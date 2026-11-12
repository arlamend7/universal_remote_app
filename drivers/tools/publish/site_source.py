"""Read a previously published driver site from a directory or HTTPS URL."""
from __future__ import annotations

import urllib.error
import urllib.request
from pathlib import Path

MAXIMUM_BYTES = 8 * 1024 * 1024


class SiteSource:
    """Read-only access to an earlier publication, for rollback protection
    and for carrying immutable objects forward into the next deployment."""

    def __init__(self, location: str | None) -> None:
        self.location = location

    def read(self, path: str) -> bytes | None:
        if not self.location:
            return None
        if self.location.startswith(("https://", "http://127.0.0.1")):
            return self._fetch(self.location.rstrip("/") + "/" + path)
        file = Path(self.location) / path
        return file.read_bytes() if file.is_file() else None

    @staticmethod
    def _fetch(url: str) -> bytes | None:
        request = urllib.request.Request(url, headers={"User-Agent": "driver-publisher"})
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                body = response.read(MAXIMUM_BYTES + 1)
        except urllib.error.HTTPError as error:
            if error.code == 404:
                return None
            raise
        if len(body) > MAXIMUM_BYTES:
            raise ValueError(f"{url} exceeds the publication size limit")
        return body
