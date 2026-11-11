#!/usr/bin/env python3
"""Validate a source tree and produce a reproducible unsigned ZIP."""
import argparse
import json
from pathlib import Path
import subprocess
import tempfile
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo


def build(source: Path, destination: Path) -> None:
    validator = Path(__file__).resolve().parents[1] / "validate" / "validate.sh"
    verified = subprocess.run(
        ["sh", str(validator), str(source.absolute())],
        stdout=subprocess.PIPE,
        check=True,
    )
    files = json.loads(verified.stdout)["files"]
    with tempfile.NamedTemporaryFile(dir=destination.parent, delete=False) as temporary:
        staging = Path(temporary.name)
    try:
        with ZipFile(staging, "w") as archive:
            for name, content in sorted(files.items()):
                entry = ZipInfo(name)
                entry.create_system = 3
                entry.external_attr = 0o100644 << 16
                archive.writestr(entry, content.encode("utf-8"), compress_type=ZIP_DEFLATED)
        staging.replace(destination)
    finally:
        staging.unlink(missing_ok=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()
    build(args.source, args.destination)
