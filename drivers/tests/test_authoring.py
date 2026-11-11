import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from zipfile import ZipFile

DRIVERS = Path(__file__).resolve().parents[1]
EXAMPLE = DRIVERS / "providers" / "example-tv"
VALIDATOR = DRIVERS / "tools" / "validate" / "validate.sh"
BUILDER = DRIVERS / "tools" / "package" / "build.py"


class DriverAuthoringTest(unittest.TestCase):
    def test_example_builds_identical_archives(self):
        with tempfile.TemporaryDirectory() as temporary:
            first = Path(temporary) / "first.zip"
            second = Path(temporary) / "second.zip"
            for path in [first, second]:
                subprocess.run(["python3", str(BUILDER), str(EXAMPLE), str(path)], check=True)
            self.assertEqual(first.read_bytes(), second.read_bytes())
            with ZipFile(first) as archive:
                manifest = json.loads(archive.read("manifest.json"))
                self.assertEqual(manifest["id"], "example.smarttv")
                self.assertIn("commands/volume-up.json", archive.namelist())

    def test_rejects_symbolic_links(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            (directory / "manifest.json").symlink_to(EXAMPLE / "manifest.json")
            result = subprocess.run(
                ["sh", str(VALIDATOR), str(directory)], capture_output=True, check=False
            )
            self.assertEqual(result.returncode, 65)
            self.assertIn(b"Unexpected entry", result.stderr)
