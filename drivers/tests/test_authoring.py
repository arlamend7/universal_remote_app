import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from zipfile import ZipFile

DRIVERS = Path(__file__).resolve().parents[1]
EXAMPLE = DRIVERS / "providers" / "example-tv" / "json-websocket"
VALIDATOR = DRIVERS / "tools" / "validate" / "validate.sh"
BUILDER = DRIVERS / "tools" / "package" / "build.py"
INTEGRATIONS = [
    "lg-webos/webos-22-plus",
    "lg-webos/webos-legacy",
    "android-tv/remote-v2",
    "samsung-tizen/tizen-supported",
    "roku-ecp/roku-supported",
    "example-tv/json-websocket",
]


class DriverAuthoringTest(unittest.TestCase):
    def test_every_integration_compiles_against_the_runtime(self):
        for integration in INTEGRATIONS:
            result = subprocess.run(
                ["sh", str(VALIDATOR), str(DRIVERS / "providers" / integration)],
                capture_output=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0, msg=f"{integration}: {result.stderr}")
            manifest = json.loads(result.stdout)["manifest"]
            self.assertNotIn("version", manifest)
            self.assertEqual(manifest["schemaVersion"], 2)

    def test_example_builds_identical_archives(self):
        with tempfile.TemporaryDirectory() as temporary:
            first = Path(temporary) / "first.zip"
            second = Path(temporary) / "second.zip"
            for path in [first, second]:
                subprocess.run([sys.executable, str(BUILDER), str(EXAMPLE), str(path)], check=True)
            self.assertEqual(first.read_bytes(), second.read_bytes())
            with ZipFile(first) as archive:
                manifest = json.loads(archive.read("manifest.json"))
                self.assertEqual(manifest["integrationId"], "example.json-websocket")
                self.assertIn("mappings.json", archive.namelist())

    def test_rejects_symbolic_links(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            (directory / "manifest.json").symlink_to(EXAMPLE / "manifest.json")
            result = subprocess.run(
                ["sh", str(VALIDATOR), str(directory)], capture_output=True, check=False
            )
            self.assertEqual(result.returncode, 65)
            self.assertIn(b"cannot contain links", result.stderr)

    def test_no_numbered_release_folders_remain(self):
        for path in (DRIVERS / "providers").rglob("*"):
            if path.is_dir():
                self.assertNotRegex(path.name, r"^\d+\.\d+\.\d+$", msg=str(path))


if __name__ == "__main__":
    unittest.main()
