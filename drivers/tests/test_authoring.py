import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from zipfile import ZipFile

DRIVERS = Path(__file__).resolve().parents[1]
EXAMPLE = DRIVERS / "fixtures" / "example-json-websocket"
VALIDATOR = DRIVERS / "tools" / "validate" / "validate.sh"
BUILDER = DRIVERS / "tools" / "package" / "build.py"
INTEGRATIONS = [
    DRIVERS / "providers" / "lg-webos" / "webos-22-plus",
    DRIVERS / "providers" / "lg-webos" / "webos-legacy",
    DRIVERS / "providers" / "android-tv" / "remote-v2",
    DRIVERS / "providers" / "samsung-tizen" / "tizen-supported",
    DRIVERS / "providers" / "roku-ecp" / "roku-supported",
    EXAMPLE,
]


class DriverAuthoringTest(unittest.TestCase):
    def test_every_integration_compiles_against_the_runtime(self):
        for integration in INTEGRATIONS:
            result = subprocess.run(
                ["sh", str(VALIDATOR), str(integration)],
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

    def test_published_index_lists_every_provider_folder_and_no_fixture(self):
        index = json.loads((DRIVERS / "catalog.json").read_text("utf-8"))
        sources = {DRIVERS / entry["source"] for entry in index["integrations"]}
        self.assertEqual(sources, set(INTEGRATIONS) - {EXAMPLE})

    def test_no_numbered_release_folders_remain(self):
        for path in (DRIVERS / "providers").rglob("*"):
            if path.is_dir():
                self.assertNotRegex(path.name, r"^\d+\.\d+\.\d+$", msg=str(path))


if __name__ == "__main__":
    unittest.main()
