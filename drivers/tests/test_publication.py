from base64 import b64decode
from hashlib import sha256
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

DRIVERS = Path(__file__).resolve().parents[1]


class DriverPublicationTest(unittest.TestCase):
    def test_signed_catalog_and_packages_match_published_paths(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            key = root / "fixture.pem"
            site = root / "site"
            subprocess.run(
                ["openssl", "genpkey", "-algorithm", "EC", "-pkeyopt",
                 "ec_paramgen_curve:P-256", "-out", str(key)],
                check=True,
            )
            subprocess.run(
                ["python3", str(DRIVERS / "tools/publish/build_site.py"),
                 "--index", str(DRIVERS / "fixtures/development-release-index.json"),
                 "--output", str(site), "--key", str(key), "--key-id", "fixture",
                 "--revision", "8"],
                check=True,
            )
            envelope = json.loads((site / "catalog.json").read_bytes())
            payload = json.loads(b64decode(envelope["payload"]))
            self.assertEqual(payload["revision"], 8)
            release, = payload["releases"]
            self.assertEqual(release["channel"], "development")
            package = (site / release["package"]).read_bytes()
            self.assertEqual(sha256(package).hexdigest(), release["sha256"])
            self.assertEqual(len(package), release["size"])
            self.assertTrue(envelope["signature"])
            self.assertTrue(release["signature"])

    def test_roku_cannot_be_included_in_a_publication(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            key = root / "fixture.pem"
            index = root / "release.json"
            index.write_text(json.dumps([{"source": "roku-ecp/1.0.0", "channel": "stable"}]))
            subprocess.run(
                ["openssl", "genpkey", "-algorithm", "EC", "-pkeyopt",
                 "ec_paramgen_curve:P-256", "-out", str(key)],
                check=True,
            )
            result = subprocess.run(
                ["python3", str(DRIVERS / "tools/publish/build_site.py"),
                 "--index", str(index), "--output", str(root / "site"),
                 "--key", str(key), "--key-id", "fixture", "--revision", "1"],
                capture_output=True, check=False,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn(b"Roku packages must remain local", result.stderr)
            self.assertFalse((root / "site").exists())

    def test_production_index_builds_only_the_three_approved_packages(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            key = root / "fixture.pem"
            site = root / "site"
            subprocess.run(
                ["openssl", "genpkey", "-algorithm", "EC", "-pkeyopt",
                 "ec_paramgen_curve:P-256", "-out", str(key)],
                check=True,
            )
            subprocess.run(
                ["python3", str(DRIVERS / "tools/publish/build_site.py"),
                 "--index", str(DRIVERS / "releases.json"), "--output", str(site),
                 "--key", str(key), "--key-id", "fixture", "--revision", "1"],
                check=True,
            )
            envelope = json.loads((site / "catalog.json").read_bytes())
            payload = json.loads(b64decode(envelope["payload"]))
            releases = payload["releases"]
            self.assertEqual(
                {release["manifest"]["providerId"] for release in releases},
                {"lg.webos", "android.tv", "samsung.tizen"},
            )
            for release in releases:
                package = (site / release["package"]).read_bytes()
                self.assertEqual(sha256(package).hexdigest(), release["sha256"])
                self.assertEqual(release["channel"], "stable")
