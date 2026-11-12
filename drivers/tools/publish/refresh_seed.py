#!/usr/bin/env python3
"""Copy a published, verified catalog and its stable packages into the app's
signed seed (``assets/driver-seed``) so a fresh install works offline.

Nothing is trusted on the way: the catalog signature, every package
SHA-256 and every package signature are verified with the public key
before anything is written. The app verifies the seed again on first run.
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from site_source import SiteSource  # noqa: E402


def refresh(site: str, public_key: Path, output: Path) -> dict:
    source = SiteSource(site)
    envelope = source.read("v2/catalog.json")
    if envelope is None:
        raise RuntimeError("The site has no v2 catalog")
    signed = json.loads(envelope)
    payload = base64.b64decode(signed["payload"])
    with tempfile.TemporaryDirectory() as scratch:
        if not _verify(public_key, payload, base64.b64decode(signed["signature"]), scratch):
            raise RuntimeError("The catalog signature does not verify with this key")
        catalog = json.loads(payload)
        objects = {}
        for entry in catalog["integrations"]:
            if entry["channel"] != "stable":
                continue
            body = source.read(entry["package"])
            if body is None or hashlib.sha256(body).hexdigest() != entry["sha256"]:
                raise RuntimeError(f"{entry['id']}: package is missing or altered")
            if not _verify(public_key, body, base64.b64decode(entry["signature"]), scratch):
                raise RuntimeError(f"{entry['id']}: package signature does not verify")
            objects[entry["sha256"]] = body
    if output.exists():
        shutil.rmtree(output)
    (output / "objects").mkdir(parents=True)
    (output / "catalog.json").write_bytes(envelope)
    for sha, body in sorted(objects.items()):
        (output / "objects" / f"{sha}.zip").write_bytes(body)
    index = {"catalog": "catalog.json", "revision": catalog["revision"],
             "objects": sorted(objects)}
    (output / "seed.json").write_text(json.dumps(index, indent=2) + "\n", "utf-8")
    return index


def _verify(public_key: Path, payload: bytes, signature: bytes, scratch: str) -> bool:
    proof = Path(scratch) / "seed.sig"
    proof.write_bytes(signature)
    result = subprocess.run(
        ["openssl", "dgst", "-sha256", "-verify", str(public_key), "-signature", str(proof)],
        input=payload, capture_output=True, check=False,
    )
    return result.returncode == 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--site", required=True, help="Published site URL or directory")
    parser.add_argument("--public-key", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    try:
        print(json.dumps(refresh(args.site, args.public_key, args.output), indent=2))
    except (RuntimeError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
