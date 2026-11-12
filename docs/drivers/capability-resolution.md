# Declarative commands and capabilities

`IntegrationDefinition.compile` (runtime, `package:remote_driver_runtime/integrations.dart`)
turns a package into executable data and rejects it when:

- the manifest's engine or any `requiredRuntime` operation kind is missing
  from this runtime (the missing kinds are named);
- a mapping key is not a runtime operation, uses a kind not declared in
  `requiredRuntime`, belongs to another engine, or fails the engine's
  parameter validation (URIs, key codes, key names, templates, decoders);
- `manifest.json#capabilities` differs from `capabilities.json`;
- a declared capability has no operation set fully mapped, or its
  verification probe is not mapped.

## Mappings

`mappings.json` binds runtime operations (`volume-up`, `key-mute`,
`read-content`, `subscribe-volume`, …) to typed engine calls. Profiles may
override any mapping with `mappingOverrides`; the override is validated with
the same rules and wins for that profile. `OperationTable.diagnostics`
reports the exact selected call (and the profile that supplied it).

There is no compiled fallback: a JSON change to a valid value changes what is
sent (`test/integrations/integration_definition_test.dart`), an invalid value
rejects the package, and an unmapped operation stays unavailable.
`readOnly: true` marks status queries whose failures never withdraw a
capability.

## Capabilities

There is no central capability table. Each declaration lists:

| Field | Effect |
|---|---|
| `alternatives` | Operation sets; the first fully executable one is used |
| `verify` | Probe run after connecting: `succeeds`, `non-empty` or `contains`; success yields `known`/`verified`, failure `unavailable` with the TV's reason |
| `when` | Session fact conditions (negotiated features, device-info flags, reported apps); false hides the capability, unknown keeps it `conditional`; `missing` decides absent facts |
| `restrictions` | OS/firmware/model ranges; mismatch or unknown software keeps it `conditional` |
| `permissions` | Protocol permissions, shown in diagnostics |
| `disableOn` | Error codes that withdraw the capability for the rest of the session |

Profiles can disable capabilities (`conditional`, source `profile`). An
operation kind the session reports unusable (for example a closed pointer
socket) makes dependent capabilities `unavailable`.

Legacy adapters no longer consult binding data for wire values (it could only
repeat compiled defaults), and the v1 managed controller derives requirements
from each bundle's own `capabilities.json`.
