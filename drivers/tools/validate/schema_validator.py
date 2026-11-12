"""A small, dependency-free JSON Schema (2020-12 subset) validator.

The driver schemas use only the keywords implemented here. Unsupported
keywords are rejected so a schema can never silently weaken validation.
"""

import json
import re
from pathlib import Path

_SUPPORTED = {
    "$schema", "$id", "$defs", "$ref", "title", "description", "type",
    "properties", "required", "additionalProperties", "propertyNames",
    "maxProperties", "enum", "const", "pattern", "minLength", "maxLength",
    "minimum", "maximum", "items", "minItems", "maxItems", "uniqueItems",
}
_TYPES = {
    "object": dict,
    "array": list,
    "string": str,
    "boolean": bool,
    "null": type(None),
}


class SchemaError(ValueError):
    """Raised when a document does not satisfy its schema."""


class SchemaSet:
    """Loads every schema in a directory and resolves cross-file references."""

    def __init__(self, directory):
        self.directory = Path(directory)
        self._schemas = {}
        for path in sorted(self.directory.glob("*.schema.json")):
            self._schemas[path.name] = json.loads(path.read_text("utf-8"))
        for name, schema in self._schemas.items():
            _check_keywords(schema, name)

    def validate(self, schema_name, document):
        self._validate(document, self._schemas[schema_name], schema_name, "$")

    def _resolve(self, reference, current):
        file_name, _, pointer = reference.partition("#")
        name = file_name or current
        node = self._schemas[name]
        for part in [segment for segment in pointer.split("/") if segment]:
            node = node[part]
        return node, name

    def _validate(self, value, schema, current, path):
        if "$ref" in schema:
            target, name = self._resolve(schema["$ref"], current)
            self._validate(value, target, name, path)
        _check_type(value, schema, path)
        _check_scalar(value, schema, path)
        if isinstance(value, dict):
            self._check_object(value, schema, current, path)
        if isinstance(value, list):
            self._check_array(value, schema, current, path)

    def _check_object(self, value, schema, current, path):
        if len(value) > schema.get("maxProperties", len(value)):
            raise SchemaError(f"{path}: too many properties")
        for key in schema.get("required", []):
            if key not in value:
                raise SchemaError(f"{path}: missing required field {key!r}")
        properties = schema.get("properties", {})
        extra = schema.get("additionalProperties", True)
        for key, item in value.items():
            if "propertyNames" in schema:
                self._validate(key, schema["propertyNames"], current, f"{path}.{key}")
            if key in properties:
                self._validate(item, properties[key], current, f"{path}.{key}")
                continue
            if extra is False:
                raise SchemaError(f"{path}: unknown field {key!r}")
            if isinstance(extra, dict):
                self._validate(item, extra, current, f"{path}.{key}")

    def _check_array(self, value, schema, current, path):
        if len(value) < schema.get("minItems", 0):
            raise SchemaError(f"{path}: too few items")
        if len(value) > schema.get("maxItems", len(value)):
            raise SchemaError(f"{path}: too many items")
        if schema.get("uniqueItems"):
            encoded = [json.dumps(item, sort_keys=True) for item in value]
            if len(set(encoded)) != len(encoded):
                raise SchemaError(f"{path}: items must be unique")
        if "items" in schema:
            for index, item in enumerate(value):
                self._validate(item, schema["items"], current, f"{path}[{index}]")


def _check_keywords(schema, name):
    if isinstance(schema, dict):
        unknown = set(schema) - _SUPPORTED
        # Property maps and $defs hold names, not keywords.
        for key in ("properties", "$defs"):
            for child in schema.get(key, {}).values():
                _check_keywords(child, name)
        for key, child in schema.items():
            if key in ("properties", "$defs", "enum", "const"):
                continue
            if isinstance(child, (dict, list)):
                _check_keywords(child, name)
        if unknown:
            raise SchemaError(f"{name}: unsupported keywords {sorted(unknown)}")
    if isinstance(schema, list):
        for child in schema:
            _check_keywords(child, name)


def _check_type(value, schema, path):
    expected = schema.get("type")
    if expected is None:
        return
    names = expected if isinstance(expected, list) else [expected]
    for name in names:
        if name == "integer" and isinstance(value, int) and not isinstance(value, bool):
            return
        if name == "number" and isinstance(value, (int, float)) and not isinstance(value, bool):
            return
        if name in _TYPES and isinstance(value, _TYPES[name]):
            if name == "boolean" or not isinstance(value, bool):
                return
    raise SchemaError(f"{path}: expected {expected}")


def _check_scalar(value, schema, path):
    if "const" in schema and value != schema["const"]:
        raise SchemaError(f"{path}: must equal {schema['const']!r}")
    if "enum" in schema and value not in schema["enum"]:
        raise SchemaError(f"{path}: {value!r} is not allowed")
    if isinstance(value, str):
        if len(value) < schema.get("minLength", 0):
            raise SchemaError(f"{path}: too short")
        if len(value) > schema.get("maxLength", len(value)):
            raise SchemaError(f"{path}: too long")
        pattern = schema.get("pattern")
        if pattern is not None and re.search(pattern, value) is None:
            raise SchemaError(f"{path}: does not match {pattern}")
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        if value < schema.get("minimum", value):
            raise SchemaError(f"{path}: below minimum")
        if value > schema.get("maximum", value):
            raise SchemaError(f"{path}: above maximum")
