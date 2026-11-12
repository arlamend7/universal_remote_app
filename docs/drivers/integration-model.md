# Integration model (schema 2)

Downloadable driver packages are **integrations** with a permanent identity.
They are never released as numbered versions.

| Field | Meaning | Where |
|---|---|---|
| `integrationId` | Permanent integration identifier, e.g. `lg.webos.22-plus` | manifest, catalog `id` |
| `providerId` | Stable provider family; matches saved-device `providerId` | manifest, catalog |
| `lastUpdatedAt` | When this integration's content was last published (display/diagnostics only) | stamped by the publisher into the manifest and catalog |
| `sha256` | Identity of the exact package bytes | catalog entry and local `objects/<sha256>/` only — never inside the package |
| `catalog.revision` | Monotonic signed catalog revision; clients reject lower or conflicting revisions | catalog payload |
| `schemaVersion` | JSON schema compatibility (`2`) | manifest and catalog |
| `requiredRuntime` | `{api, operations}`: runtime API level and engine operation kinds | manifest and catalog |
| `osVersion` / `firmwareVersion` / `models` | Physical-device ranges, compared with a declared `versionScheme` (`dotted-numeric` or `exact`) | `compatibility` and per-profile `compatibility` |

## Files in a package

| File | Contents | Schema |
|---|---|---|
| `manifest.json` | Identity, engine, runtime, credential scope, compatibility, profiles, capability summary, replaced legacy families | `drivers/schema/v2/manifest.schema.json` |
| `capabilities.json` | Per capability: alternative operation sets, verification probe, fact conditions, OS/firmware/model restrictions, permissions, `disableOn` error codes | `capabilities.schema.json` |
| `mappings.json` | Runtime operation → typed engine call (`kind` + engine-validated parameters) | `mappings.schema.json` |
| `discovery.json`, `connection.json`, `identification.json`, `workflows/*.json` | Discovery evidence, session policy, software identification | added with the runtime phases |

## Compatibility profiles

Every integration has at least one `bootstrap` profile, usable before
authentication (it cannot claim OS/firmware ranges it has not seen). `identified`
profiles apply after the authenticated session reports software. Profiles may
disable capabilities and override operation mappings; they never change the
protocol engine. Unknown device software never matches a declared range.

## Signed catalog

`v2/catalog.json` is the same `{keyId, payload, signature}` envelope as v1
(P-256 ECDSA over the payload bytes). Each entry references the immutable
object `packages/objects/<sha256>/driver.zip` that matches its hash, so a CDN
cannot serve a different generation under the same name.

## Validation sources

- JSON Schemas in `drivers/schema/v2` define structure; the stdlib-only
  validator in `drivers/tools/validate/schema_validator.py` executes them.
- Dart decoders (`remote_core/lib/src/integrations`, `remote_driver_manager/lib/src/catalog`)
  decode the same fixtures in `drivers/fixtures/v2`; a Dart test checks that the
  schema capability enum equals `RemoteCapability`.
- Engine-specific mapping parameters are validated by the compiled engines.
