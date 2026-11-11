#!/usr/bin/env python3
"""Build and validate a complete signed GitHub Pages artifact."""
import argparse
from base64 import b64encode
from datetime import datetime, timezone
from hashlib import sha256
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile
from zipfile import ZipFile

TOOLS = Path(__file__).resolve().parents[1]
DRIVERS = TOOLS.parent
sys.path.insert(0, str(TOOLS / "sign"))
from driver_signer import DriverSigner


def encode(value: object) -> bytes:
    return json.dumps(value, separators=(",", ":"), ensure_ascii=False).encode()


def b64(value: bytes) -> str:
    return b64encode(value).decode("ascii")


def release_entries(index: Path) -> list:
    entries = json.loads(index.read_text())
    if not isinstance(entries, list) or len(entries) > 1024:
        raise ValueError("Invalid driver release index")
    return entries


def package(entry: dict, output: Path, scratch: Path, signer: DriverSigner) -> dict:
    if not isinstance(entry, dict) or set(entry) - {"source", "channel", "publishedAt", "notes"}:
        raise ValueError("Invalid release entry")
    source = entry["source"]
    if not re.fullmatch(r"[a-z0-9_-]+(?:/[a-z0-9._-]+)?", source):
        raise ValueError("Invalid release source")
    folder = (DRIVERS / "providers" / source).resolve()
    if not folder.is_relative_to(DRIVERS / "providers"):
        raise ValueError("Release source escapes the provider directory")
    channel = entry["channel"]
    if channel not in {"stable", "development"}:
        raise ValueError("Invalid release channel")
    zip_path = scratch / "driver.zip"
    subprocess.run(
        [sys.executable, str(TOOLS / "package" / "build.py"), str(folder), str(zip_path)],
        check=True,
    )
    data = zip_path.read_bytes()
    with ZipFile(zip_path) as archive:
        manifest = json.loads(archive.read("manifest.json"))
        discovery = json.loads(archive.read("discovery.json"))
    if manifest["providerId"] == "roku.ecp":
        raise ValueError("Roku packages must remain local")
    if manifest["providerId"] == "example.tv" and channel != "development":
        raise ValueError("The fictional driver is development-only")
    relative = f"packages/{manifest['id']}/{manifest['version']}/driver.zip"
    target = output / relative
    if target.exists():
        raise ValueError("Duplicate package version")
    target.parent.mkdir(parents=True)
    target.write_bytes(data)
    release = {
        "manifest": manifest,
        "discovery": discovery,
        "channel": channel,
        "package": relative,
        "size": len(data),
        "sha256": sha256(data).hexdigest(),
        "signature": b64(signer.sign(data)),
    }
    notes = entry.get("notes")
    if notes is not None:
        if not isinstance(notes, str) or len(notes) > 4096:
            raise ValueError("Invalid release notes")
        release["notes"] = notes
    published = entry.get("publishedAt")
    if published is not None:
        if not isinstance(published, str) or not published.endswith("Z"):
            raise ValueError("Invalid publication timestamp")
        datetime.fromisoformat(published[:-1] + "+00:00")
        release["publishedAt"] = published
    return release


def build(index: Path, output: Path, key: Path, key_id: str, revision: int) -> None:
    if not re.fullmatch(r"[a-z][a-z0-9_-]{0,63}", key_id) or revision < 1:
        raise ValueError("Invalid signing key ID or catalog revision")
    if output.exists():
        raise ValueError("Output directory must not already exist")
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=output.parent) as temporary:
        scratch = Path(temporary)
        signer = DriverSigner(key, scratch)
        site = scratch / "site"
        site.mkdir()
        releases = [package(entry, site, scratch, signer) for entry in release_entries(index)]
        payload = encode({
            "schemaVersion": 1,
            "revision": revision,
            "publishedAt": datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z"),
            "releases": sorted(releases, key=lambda release: release["package"]),
        })
        envelope = encode({"keyId": key_id, "payload": b64(payload), "signature": b64(signer.sign(payload))})
        if len(envelope) > 2 * 1024 * 1024:
            raise ValueError("Catalog exceeds runtime size limit")
        (site / "catalog.json").write_bytes(envelope)
        (site / "index.html").write_text(
            "<!doctype html><meta charset=utf-8><title>Universal Remote drivers</title>"
            "<a href=catalog.json>Signed driver catalog</a>\n"
        )
        site.rename(output)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--index", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--key", required=True, type=Path)
    parser.add_argument("--key-id", required=True)
    parser.add_argument("--revision", required=True, type=int)
    args = parser.parse_args()
    build(args.index, args.output, args.key, args.key_id, args.revision)
