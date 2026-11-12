from __future__ import annotations

import base64
import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from argparse import Namespace
from pathlib import Path

DRIVERS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(DRIVERS / "tools" / "publish"))

from build_site import PublicationError, build  # noqa: E402
from refresh_seed import refresh  # noqa: E402

EXAMPLE = DRIVERS / "fixtures" / "example-json-websocket"


def _key(directory: Path, name: str = "key.pem") -> Path:
    key = directory / name
    subprocess.run(["openssl", "genpkey", "-algorithm", "EC", "-pkeyopt",
                    "ec_paramgen_curve:P-256", "-out", str(key)], check=True,
                   capture_output=True)
    return key


def _public(directory: Path, key: Path) -> Path:
    public = directory / "public.pem"
    subprocess.run(["openssl", "pkey", "-in", str(key), "-pubout", "-out", str(public)],
                   check=True, capture_output=True)
    return public


def _catalog(site: Path) -> dict:
    envelope = json.loads((site / "v2" / "catalog.json").read_text("utf-8"))
    return json.loads(base64.b64decode(envelope["payload"]))


class PublicationTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.key = _key(self.root)
        self.source = self.root / "example"
        shutil.copytree(EXAMPLE, self.source)
        self.index = self.root / "catalog.json"
        self.index.write_text(json.dumps({"schemaVersion": 2, "integrations": [
            {"source": str(self.source), "channel": "stable"}]}), "utf-8")

    def tearDown(self):
        self.temporary.cleanup()

    def _build(self, output: str, previous: str | None = None, **overrides):
        options = {"index": str(self.index), "output": str(self.root / output),
                   "key": str(self.key), "key_id": "ci-fixture", "previous": previous,
                   "revision": None, "published_at": "2026-11-11T21:25:00Z", "report": None}
        options.update(overrides)
        return build(Namespace(**options))

    def test_first_publication_writes_immutable_objects(self):
        report = self._build("site")
        catalog = _catalog(self.root / "site")
        entry = catalog["integrations"][0]
        self.assertEqual(report["revision"], 1)
        self.assertEqual(entry["package"], f"packages/objects/{entry['sha256']}/driver.zip")
        self.assertTrue((self.root / "site" / entry["package"]).is_file())
        self.assertEqual(entry["lastUpdatedAt"], "2026-11-11T21:25:00Z")
        self.assertNotIn("version", entry)

    def test_unchanged_content_reuses_the_generation_and_revision(self):
        self._build("first")
        report = self._build("second", previous=str(self.root / "first"),
                             published_at="2026-11-12T08:00:00Z")
        self.assertFalse(report["changed"])
        self.assertEqual(report["revision"], 1)
        self.assertEqual(report["integrations"][0]["status"], "unchanged")
        self.assertEqual(report["integrations"][0]["lastUpdatedAt"], "2026-11-11T21:25:00Z")
        self.assertEqual((self.root / "first" / "v2" / "catalog.json").read_bytes(),
                         (self.root / "second" / "v2" / "catalog.json").read_bytes())

    def test_editing_json_updates_in_place_and_keeps_the_previous_object(self):
        self._build("first")
        first = _catalog(self.root / "first")["integrations"][0]
        mappings = json.loads((self.source / "mappings.json").read_text("utf-8"))
        mappings["volume-up"]["message"]["type"] = "volumeUpV2"
        (self.source / "mappings.json").write_text(json.dumps(mappings), "utf-8")
        report = self._build("second", previous=str(self.root / "first"),
                             published_at="2026-11-12T08:00:00Z")
        second = _catalog(self.root / "second")["integrations"][0]
        self.assertTrue(report["changed"])
        self.assertEqual(report["revision"], 2)
        self.assertEqual(second["id"], first["id"])
        self.assertNotEqual(second["sha256"], first["sha256"])
        self.assertEqual(second["lastUpdatedAt"], "2026-11-12T08:00:00Z")
        self.assertIn(first["sha256"], report["carriedObjects"])
        self.assertTrue((self.root / "second" / first["package"]).is_file())
        self.assertEqual(sorted(p.name for p in (self.source.parent).iterdir()
                                if p.name.startswith("example")), ["example"])

    def test_revision_reuse_and_foreign_keys_are_refused(self):
        self._build("first")
        (self.source / "capabilities.json").write_text(json.dumps({
            "volume": {"alternatives": [["volume-up", "volume-down"]]},
            "volumeFeedback": {"alternatives": [["read-volume"]]},
        }), "utf-8")
        with self.assertRaises(PublicationError):
            self._build("second", previous=str(self.root / "first"), revision=1)
        other = _key(self.root, "other.pem")
        with self.assertRaises(PublicationError):
            self._build("third", previous=str(self.root / "first"), key=str(other))

    def test_package_versions_in_sources_are_refused(self):
        manifest = json.loads((self.source / "manifest.json").read_text("utf-8"))
        manifest["version"] = "1.0.0"
        (self.source / "manifest.json").write_text(json.dumps(manifest), "utf-8")
        with self.assertRaises(PublicationError):
            self._build("site")

    def test_seed_contains_only_verified_stable_packages(self):
        self._build("site")
        seed = refresh(str(self.root / "site"), _public(self.root, self.key),
                       self.root / "seed")
        catalog = _catalog(self.root / "site")
        self.assertEqual(seed["objects"], [catalog["integrations"][0]["sha256"]])
        self.assertTrue((self.root / "seed" / "objects" / f"{seed['objects'][0]}.zip").is_file())
        other = _key(self.root, "other.pem")
        with self.assertRaises(RuntimeError):
            refresh(str(self.root / "site"), _public(self.root, other), self.root / "bad")


if __name__ == "__main__":
    unittest.main()
