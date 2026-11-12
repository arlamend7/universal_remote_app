# Driver architecture

One authoritative driver system: compiled, trusted **protocol engines** driven
by signed, content-addressed **integration** definitions. No manufacturer is
named in generic application, controller or registration code (a structure
rule rejects provider-ID literals outside driver data and engines).

```text
                       drivers/ (independent project, JSON only)
                       providers/<provider>/<family>/*.json
                                    │  build_site.py (validate, digest,
                                    │  sign, immutable objects, revision)
                                    ▼
             GitHub Pages: v2/catalog.json + packages/objects/<sha256>/driver.zip
                                    │  HTTPS (ETag), signature + SHA-256 checked
                                    ▼
┌───────────────────────────── apps/universal_remote_app ─────────────────────────────┐
│ AppBootstrap → IntegrationService (seed, migrate, register providers, updates)     │
│ ConnectionController / Discovery / Driver Explorer / Device details                 │
└───────────────┬─────────────────────────────────────────────────────┬───────────────┘
                │                                                     │
   remote_driver_manager                                     remote_ui (widgets)
   catalog · content-addressed installer · update service
   IntegrationResolver (two-stage) · ManagedIntegrationPlanner
   IntegrationProviderSource (generic ProviderDefinitions)
                │
   remote_driver_runtime
   GenericTvController ─ SessionOpener ─ OperationGate ─ CapabilityResolver
   IntegrationDefinition (compile JSON against engines) · DiscoveryRules · DeviceRules
   engines: ssap · android-remote-v2 · samsung-channel · roku-ecp · json-websocket
                │
   remote_network (SSDP, mDNS, WebSocket, TLS pinning, WoL)   remote_core (contracts)
```

## Package responsibilities and dependency graph

| Package | Owns | Depends on |
|---|---|---|
| `remote_core` | Device, capability, evidence and `TVRemoteBase` contracts; integration identity, manifest, compatibility profiles, version ranges, capability declarations, operation mappings, runtime operation vocabulary; provider registry and discovery contracts | — |
| `remote_network` | SSDP, Bonjour/mDNS, unicast probes, WebSocket/TLS transports, certificate inspection, Wake-on-LAN | `remote_core` |
| `remote_driver_runtime` | Protocol engines and their protocol libraries, integration compilation, generic controller and session lifecycle, declarative discovery/setup/policy/wake | `remote_core`, `remote_network` |
| `remote_driver_manager` | Signed catalog, package verification, content-addressed installation, inventory and migration, hash-based updates, two-stage resolution, planner, provider source, integration service | `remote_core`, `remote_network`, `remote_driver_runtime` |
| `remote_ui` | Remote controls, device software details | `remote_core` |
| `universal_remote_app` | Composition root, platform storage/verification, Driver Explorer | all |

There are no package cycles (`tool/check_structure.dart`, `tool/audit_dependencies.dart`).

## Connection flow

```text
discover (declarative identifier) → provider family → GenericTvController.connect
  → planner.prepare: bootstrap integration (assignment / priority / model),
    load verified generation or install (seed → catalog), compile
  → engine.open: authenticate, reuse device-scoped credentials and pins
  → identify-software → planner.refine (≤ 1 handoff) → verification probes
  → capabilities from declarations → remember assignment → connected
```

See `integration-model.md`, `installation.md`, `protocol-engines.md`,
`capability-resolution.md`, `device-version-resolution.md`,
`session-lifecycle.md` and `publishing.md` for each part.

## Configuration

Values are passed as Dart defines from `apps/universal_remote_app/.env`
(git-ignored; copy `.env.example`): `flutter run --dart-define-from-file=.env`.
The VS Code launch configurations pass it automatically.

| Define | Effect |
|---|---|
| `DRIVER_TRUSTED_KEYS` | Required for distribution and seed verification (key ID → P-256 point) |
| `DRIVER_CATALOG_BASE_URL` | Pages base URL; without it the app works from the seed and installed packages only |
| `DRIVER_LOCAL_PATH` | Non-release builds: install integration folders from disk |
| `ALLOW_DEVELOPMENT_INTEGRATIONS` | Non-release builds: offer development-channel integrations (Roku ECP) |
