#!/usr/bin/env python3
"""Build the signed, content-addressed driver site for GitHub Pages.

Authors only edit integration JSON. For every integration listed in
``drivers/catalog.json`` this tool:

* validates the folder with the compiled runtime engines and the schemas;
* computes a source digest that ignores ``lastUpdatedAt``; an unchanged
  digest reuses the previous ``lastUpdatedAt`` so the deterministic package
  (and its SHA-256) is identical, while a changed digest stamps the
  publication time;
* writes the immutable object ``packages/objects/<sha256>/driver.zip``,
  signs it, and lists it in ``v2/catalog.json`` with a strictly increasing,
  signed revision (an unchanged publication keeps its revision);
* carries forward objects referenced by the previous catalog (a Pages
  deployment replaces the whole site) and the frozen v1 catalog;
* verifies the output and writes a publication report.
"""
from __future__ import annotations

import argparse
import base64
import datetime
import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from zipfile import ZIP_STORED, ZipFile, ZipInfo

TOOLS = Path(__file__).resolve().parents[1]
DRIVERS = TOOLS.parent
sys.path.insert(0, str(TOOLS / "sign"))
sys.path.insert(0, str(TOOLS / "validate"))
sys.path.insert(0, str(Path(__file__).resolve().parent))

from driver_signer import DriverSigner  # noqa: E402
from schema_validator import SchemaSet  # noqa: E402
from site_source import SiteSource  # noqa: E402

CATALOG = "v2/catalog.json"
MAXIMUM_PACKAGE = 4 * 1024 * 1024
MAXIMUM_CATALOG = 2 * 1024 * 1024
SCHEMA_FILES = [
    ("manifest.json", "manifest.schema.json"),
    ("capabilities.json", "capabilities.schema.json"),
    ("mappings.json", "mappings.schema.json"),
]


class PublicationError(RuntimeError):
    """The publication would be unsafe or inconsistent."""


def build(args: argparse.Namespace) -> dict:
    index = json.loads(Path(args.index).read_text("utf-8"))
    if index.get("schemaVersion") != 2 or not isinstance(index.get("integrations"), list):
        raise PublicationError("drivers/catalog.json must be a schema-2 source index")
    schemas = SchemaSet(DRIVERS / "schema" / "v2")
    output = Path(args.output)
    if output.exists():
        shutil.rmtree(output)
    (output / "v2").mkdir(parents=True)
    site = SiteSource(args.previous)
    with tempfile.TemporaryDirectory() as scratch:
        signer = DriverSigner(Path(args.key), Path(scratch))
        previous = _previous(site, signer, schemas)
        published_at = args.published_at or _now()
        entries, report = [], []
        for source in index["integrations"]:
            entry, status = _integration(source, previous, published_at, signer, schemas, output)
            entries.append(entry)
            report.append({"id": entry["id"], "status": status, "sha256": entry["sha256"],
                           "lastUpdatedAt": entry["lastUpdatedAt"], "channel": entry["channel"]})
        _check_unique(entries)
        changed = previous is None or _summary(entries) != _summary(previous["integrations"])
        revision = _revision(args.revision, previous, changed)
        payload = {
            "schemaVersion": 2,
            "revision": revision,
            "publishedAt": published_at if changed else previous["publishedAt"],
            "integrations": entries,
        }
        schemas.validate("catalog.schema.json", payload)
        _write_catalog(output, payload, signer, args.key_id, previous if not changed else None, site)
        carried = _carry_forward(site, previous, output)
        _verify(output, signer, schemas)
    result = {"revision": revision, "changed": changed, "publishedAt": payload["publishedAt"],
              "integrations": report, "carriedObjects": carried}
    if args.report:
        Path(args.report).write_text(json.dumps(result, indent=2) + "\n", "utf-8")
    return result


def _integration(source, previous, published_at, signer, schemas, output):
    folder = DRIVERS / source["source"]
    channel = source.get("channel")
    if channel not in {"stable", "development"}:
        raise PublicationError(f"{source['source']}: unknown channel")
    files = _validated_files(folder)
    manifest = json.loads(files["manifest.json"])
    if "lastUpdatedAt" in manifest or "version" in manifest:
        raise PublicationError(f"{folder}: lastUpdatedAt is stamped by the publisher and "
                               "integrations have no release version")
    for name, schema in SCHEMA_FILES:
        schemas.validate(schema, json.loads(files[name]))
    digest = _source_digest(files)
    prior = _prior_entry(previous, manifest["integrationId"])
    unchanged = prior is not None and prior.get("sourceDigest") == digest
    stamp = prior["lastUpdatedAt"] if unchanged else published_at
    package = _package(files, manifest, stamp)
    sha = hashlib.sha256(package).hexdigest()
    if unchanged and sha != prior["sha256"]:
        raise PublicationError(f"{manifest['integrationId']}: rebuilding unchanged content "
                               "produced different bytes; packaging is not deterministic")
    if len(package) > MAXIMUM_PACKAGE:
        raise PublicationError(f"{manifest['integrationId']}: package exceeds 4 MB")
    target = output / "packages" / "objects" / sha / "driver.zip"
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(package)
    signature = prior["signature"] if unchanged else None
    entry = _entry(manifest, files, channel, stamp, sha, package, signer, digest, signature)
    return entry, ("unchanged" if unchanged else "updated" if prior else "new")


def _validated_files(folder: Path) -> dict:
    validator = DRIVERS / "tools" / "validate" / "validate.sh"
    result = subprocess.run(["sh", str(validator), str(folder)], capture_output=True, check=False)
    if result.returncode != 0:
        raise PublicationError(f"{folder}: {result.stderr.decode().strip()}")
    return json.loads(result.stdout)["files"]


def _source_digest(files: dict) -> str:
    canonical = {name: json.loads(text) for name, text in files.items()}
    canonical["manifest.json"].pop("lastUpdatedAt", None)
    encoded = json.dumps(canonical, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    return hashlib.sha256(encoded.encode("utf-8")).hexdigest()


def _package(files: dict, manifest: dict, stamp: str) -> bytes:
    stamped = dict(files)
    stamped["manifest.json"] = json.dumps({**manifest, "lastUpdatedAt": stamp},
                                          indent=2, ensure_ascii=False) + "\n"
    with tempfile.TemporaryFile() as buffer:
        with ZipFile(buffer, "w") as archive:
            for name, content in sorted(stamped.items()):
                info = ZipInfo(name)
                info.create_system = 3
                info.external_attr = 0o100644 << 16
                archive.writestr(info, content.encode("utf-8"), compress_type=ZIP_STORED)
        buffer.seek(0)
        return buffer.read()


def _conditional(capabilities: dict) -> list:
    return [
        name for name, declaration in capabilities.items()
        if declaration.get("when") or declaration.get("restrictions")
        or declaration.get("verify") or declaration.get("availability") == "conditional"
    ]


def _entry(manifest, files, channel, stamp, sha, package, signer, digest, signature) -> dict:
    entry = {
        "id": manifest["integrationId"],
        "providerId": manifest["providerId"],
        "name": manifest["name"],
        "manufacturer": manifest["manufacturer"],
        "platform": manifest["platform"],
        "engine": manifest["engine"],
        "channel": channel,
        "lastUpdatedAt": stamp,
        "requiredRuntime": manifest["requiredRuntime"],
        "compatibility": manifest["compatibility"],
        "profiles": manifest["profiles"],
        "capabilities": manifest["capabilities"],
        "conditionalCapabilities": _conditional(json.loads(files["capabilities.json"])),
        "package": f"packages/objects/{sha}/driver.zip",
        "sha256": sha,
        "size": len(package),
        "signature": signature or base64.b64encode(signer.sign(package)).decode(),
        "sourceDigest": digest,
    }
    for optional in ["discovery.json", "device.json"]:
        if optional in files:
            entry[optional.removesuffix(".json")] = json.loads(files[optional])
    if manifest.get("priority"):
        entry["priority"] = manifest["priority"]
    if manifest.get("replaces"):
        entry["replaces"] = manifest["replaces"]
    return entry


def _verify_signature(signer: DriverSigner, payload: bytes, signature: bytes) -> bool:
    proof = Path(signer.scratch) / "verify.sig"
    proof.write_bytes(signature)
    result = subprocess.run(
        ["openssl", "dgst", "-sha256", "-verify", str(signer.public_key), "-signature", str(proof)],
        input=payload, capture_output=True, check=False,
    )
    return result.returncode == 0


def _previous(site: SiteSource, signer: DriverSigner, schemas: SchemaSet):
    envelope = site.read(CATALOG)
    if envelope is None:
        return None
    signed = json.loads(envelope)
    payload = base64.b64decode(signed["payload"])
    if not _verify_signature(signer, payload, base64.b64decode(signed["signature"])):
        raise PublicationError("The published catalog is not signed by this key; refusing to "
                               "replace it")
    decoded = json.loads(payload)
    schemas.validate("catalog.schema.json", decoded)
    return decoded


def _prior_entry(previous, integration_id):
    if previous is None:
        return None
    return next((entry for entry in previous["integrations"] if entry["id"] == integration_id),
                None)


def _summary(entries) -> list:
    return sorted((entry["id"], entry["sha256"], entry["channel"]) for entry in entries)


def _revision(requested, previous, changed) -> int:
    current = previous["revision"] if previous else 0
    if not changed and requested is None:
        return current
    revision = requested if requested is not None else current + 1
    if revision <= current:
        raise PublicationError(f"Revision {revision} must be greater than the published "
                               f"revision {current}")
    return revision


def _check_unique(entries) -> None:
    ids = [entry["id"] for entry in entries]
    if len(ids) != len(set(ids)):
        raise PublicationError("Integration IDs must be unique")


def _write_catalog(output, payload, signer, key_id, unchanged, site) -> None:
    if unchanged is not None:
        # Identical content keeps the exact signed envelope: same revision,
        # same bytes, so clients see no revision conflict.
        (output / CATALOG).write_bytes(site.read(CATALOG))
        return
    encoded = json.dumps(payload, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    envelope = json.dumps({"keyId": key_id, "payload": base64.b64encode(encoded).decode(),
                           "signature": base64.b64encode(signer.sign(encoded)).decode()})
    if len(envelope) > MAXIMUM_CATALOG:
        raise PublicationError("The catalog exceeds 2 MB")
    (output / CATALOG).write_text(envelope, "utf-8")


def _carry_forward(site: SiteSource, previous, output: Path) -> list:
    carried = []
    for entry in (previous or {}).get("integrations", []):
        target = output / entry["package"]
        if target.exists():
            continue
        body = site.read(entry["package"])
        if body is None or hashlib.sha256(body).hexdigest() != entry["sha256"]:
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(body)
        carried.append(entry["sha256"])
    legacy = site.read("catalog.json")
    if legacy is not None:
        (output / "catalog.json").write_bytes(legacy)
        carried.extend(_carry_legacy(site, legacy, output))
    return carried


def _carry_legacy(site: SiteSource, envelope: bytes, output: Path) -> list:
    """Keep the frozen v1 catalog's packages so older app builds still work."""
    try:
        payload = json.loads(base64.b64decode(json.loads(envelope)["payload"]))
        releases = payload.get("releases", [])
    except (KeyError, ValueError, TypeError):
        return []
    carried = []
    for release in releases:
        path = release.get("package", "")
        if not path.startswith("packages/") or ".." in path:
            continue
        body = site.read(path)
        if body is None or hashlib.sha256(body).hexdigest() != release.get("sha256"):
            continue
        target = output / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(body)
        carried.append(release["sha256"])
    return carried


def _verify(output: Path, signer: DriverSigner, schemas: SchemaSet) -> None:
    signed = json.loads((output / CATALOG).read_text("utf-8"))
    payload = base64.b64decode(signed["payload"])
    if not _verify_signature(signer, payload, base64.b64decode(signed["signature"])):
        raise PublicationError("The generated catalog signature does not verify")
    catalog = json.loads(payload)
    schemas.validate("catalog.schema.json", catalog)
    for entry in catalog["integrations"]:
        body = (output / entry["package"]).read_bytes()
        if hashlib.sha256(body).hexdigest() != entry["sha256"] or len(body) != entry["size"]:
            raise PublicationError(f"{entry['id']}: object does not match its catalog entry")
        if not _verify_signature(signer, body, base64.b64decode(entry["signature"])):
            raise PublicationError(f"{entry['id']}: package signature does not verify")


def _now() -> str:
    return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--index", default=str(DRIVERS / "catalog.json"))
    parser.add_argument("--output", required=True)
    parser.add_argument("--key", required=True)
    parser.add_argument("--key-id", required=True)
    parser.add_argument("--previous", help="Published site URL or directory")
    parser.add_argument("--revision", type=int)
    parser.add_argument("--published-at")
    parser.add_argument("--report")
    args = parser.parse_args()
    try:
        result = build(args)
    except PublicationError as error:
        print(f"error: {error}", file=sys.stderr)
        return 2
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
