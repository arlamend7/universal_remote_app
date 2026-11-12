import copy
import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools" / "validate"))

from schema_validator import SchemaError, SchemaSet  # noqa: E402

FIXTURES = ROOT / "fixtures" / "v2"


def _load(name):
    return json.loads((FIXTURES / name).read_text("utf-8"))


class SchemaTest(unittest.TestCase):
    def setUp(self):
        self.schemas = SchemaSet(ROOT / "schema" / "v2")

    def test_shared_fixtures_satisfy_their_schemas(self):
        self.schemas.validate("manifest.schema.json", _load("manifest.json"))
        self.schemas.validate("catalog.schema.json", _load("catalog-payload.json"))
        self.schemas.validate("capabilities.schema.json", _load("capabilities.json"))
        self.schemas.validate("mappings.schema.json", _load("mappings.json"))

    def test_manifest_has_no_package_version(self):
        manifest = _load("manifest.json")
        manifest["version"] = "1.0.0"
        with self.assertRaises(SchemaError):
            self.schemas.validate("manifest.schema.json", manifest)

    def test_catalog_requires_immutable_object_paths(self):
        catalog = _load("catalog-payload.json")
        catalog["integrations"][0]["package"] = "packages/example/1.0.0/driver.zip"
        with self.assertRaises(SchemaError):
            self.schemas.validate("catalog.schema.json", catalog)

    def test_unknown_capability_is_rejected(self):
        capabilities = copy.deepcopy(_load("capabilities.json"))
        capabilities["teleport"] = {"alternatives": [["volume-up"]]}
        with self.assertRaises(SchemaError):
            self.schemas.validate("capabilities.schema.json", capabilities)

    def test_mapping_requires_engine_kind(self):
        with self.assertRaises(SchemaError):
            self.schemas.validate("mappings.schema.json", {"volume-up": {"command": "x"}})


if __name__ == "__main__":
    unittest.main()
