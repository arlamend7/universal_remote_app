"""Sign and verify driver artifacts with a configured P-256 key."""
from __future__ import annotations

import subprocess
from pathlib import Path

P256_SPKI = bytes.fromhex("3059301306072a8648ce3d020106082a8648ce3d030107034200")


class DriverSigner:
    def __init__(self, private_key: Path, scratch: Path) -> None:
        self.private_key = private_key
        self.scratch = scratch
        self.public_key = scratch / "driver-public.pem"
        self.public_key.write_bytes(self._openssl("pkey", "-in", str(private_key), "-pubout"))
        encoded = self._openssl(
            "pkey", "-pubin", "-in", str(self.public_key), "-outform", "DER"
        )
        if not encoded.startswith(P256_SPKI) or len(encoded) != len(P256_SPKI) + 65:
            raise ValueError("The signing key must be P-256")

    def sign(self, payload: bytes) -> bytes:
        proof = self._openssl("dgst", "-sha256", "-sign", str(self.private_key), data=payload)
        signature = self.scratch / "artifact.sig"
        signature.write_bytes(proof)
        self._openssl(
            "dgst", "-sha256", "-verify", str(self.public_key),
            "-signature", str(signature), data=payload,
        )
        return proof

    @staticmethod
    def _openssl(*args: str, data: bytes | None = None) -> bytes:
        return subprocess.run(
            ["openssl", *args], input=data, stdout=subprocess.PIPE, check=True
        ).stdout
