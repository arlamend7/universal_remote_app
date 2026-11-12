# Core contract consolidation audit

Baseline `168882c`. The workspace has six packages. Core has no production dependencies on another workspace package. Network, runtime, manager, UI, and the app consume core. Runtime also uses network. Manager uses runtime and network. The app composes manager, runtime, network and UI. Driver source, schemas, and publishing tests are under `drivers/`.

## Public API inventory

| Surface | Existing contracts and consumers |
| --- | --- |
| Device and control | Core exports `RemoteDevice`, `RemoteBase`, `TVRemoteBase`, `ACRemoteBase`, control enums, catalog entries, content, audio state and capability evidence. The runtime implements the TV contract. UI and the app consume it for session execution and rendering. |
| Discovery and pairing | Core exports typed discovery protocol IDs, observations, requirements, provider identifiers, matches, cancellation, failure, session workflow, pairing codes and credential storage interfaces. Network supplies protocol executors. Runtime binds discovery and pairing to integrations. The app supplies platform permissions and secure storage. |
| Integration and compatibility | Core exports manifests, identity, compatibility profiles, version ranges, operation mappings, capability declarations and their validators. Runtime resolves commands and parses results. Manager owns catalog trust, installation and profile selection. Publishing tools validate the same source format. |
| UI extension points | `remote_ui.dart` exports grid definitions, editor and rendering widgets. `RemoteAction`, `RemoteInput`, `RemoteInfo` and `RemoteCollection` are UI definitions with visual and interaction behavior. `RemotePanelSession` exposes Flutter listeners and host command execution. |
| Distribution and persistence | Manager exposes signed catalogs, package storage and connection planning. The app owns saved-device, settings and dashboard mappers and adapters. Network owns socket, WebSocket, local address and wake transport implementations. |

## Duplication candidates

| Definitions | Semantic purpose and consumers | Differences to preserve | Canonical owner and replacement | Migration impact | Risk | Status |
| --- | --- | --- | --- | --- | --- | --- |
| `remote_ui/src/devices/tv_remote_device.dart`, `remote_ui/src/rendering/viewmodels/grid_remote_viewmodel.dart`, `remote_core/src/tv_remote_base.dart` | Typed TV controls consumed by dashboard item definitions, the collection picker and the renderer. | UI adds feedback refresh, preview state, session guards, app history, text submission and error presentation. Core represents provider commands and streamed observations. | Keep the TV command contract in core. Remove the parallel UI interface and retain viewmodel-owned interaction behavior. | Update typed element registrations, grid consumers and extension fixtures. | Medium | Validated |
| `RemoteBase`, `RemoteDriver`, `RemotePanelSession` | Core device lifecycle versus the UI session host used by the editor and app. | The UI host exposes Flutter `ValueListenable` state, command error presentation and refresh hooks. Core lifecycle methods have no Flutter dependency. | Preserve the UI host where it owns presentation and review forwarding methods independently. | Host APIs and widget tests. | Medium | Intentional boundary |
| Models and enums declared inside `tv_remote_base.dart` and `device.dart` | TV catalog entries, content, navigation, volume, lifecycle and capabilities are reused throughout the workspace. | DTOs and enums are already canonical. Their files couple unrelated declarations. | Keep existing core types and exports. Split by domain where ownership becomes clearer. | Imports and serialized enum names remain stable. | Low | Validated |
| `installation/integration_metadata_keys.dart` and UI device software details | Both name persisted integration ID, profile ID and package hash fields. | Manager also removes retired keys. UI only reads current values. | Move current shared keys to core and keep legacy cleanup in manager. | Preserve exact saved strings and unknown metadata. | Low | Validated |
| `trustedCertificateDer`, `lastConnectedAt`, wake metadata and identity fields in runtime setup, discovery, app and UI | Stable per-device storage fields for TLS pinning, identity, wake and recent connections. | Transport parameters can share a spelling with a persisted field while having a separate meaning. Certificate values and pins remain protected from logs. | Centralize shared persisted field names in core. Leave protocol payload and UI-private fields with their owners. | Saved profiles, manual setup, wake learning, launch selection and certificate tests. | High | Validated |
| `RuntimeOperations`, generic TV controller and integration mappings | Maps TV commands to stable operation IDs used by the loader, controller, JSON and schemas. | Vendor-specific SSAP URIs, Android key codes, Samsung keys and Roku routes are distinct wire operations. | Canonical Dart operation vocabulary in core. Keep authored wire mappings with the integrations and validate references. | Driver package validation, schema constraints and parity fixtures. | High | Validated |
| LG webOS legacy and webOS 22+ definitions in `drivers/providers/lg-webos/` | Same provider with different firmware profiles and protocol policy. | Signed immutable packages and profile-specific parameters have independent compatibility boundaries. | Keep each driver folder self-contained, including repeated values. Preserve package identity, signature input and compatibility. | Publishing tool and verified seed artifacts. | High | Intentional independence |
| Core local-address validation, network MAC normalization, runtime wake policy and app neighbour parsing | Network eligibility and address handling. | Address validation serves connection policy. MAC normalization canonicalizes wire input. Neighbour parsing is platform I/O and wake eligibility includes device policy. | Resolve saved Wake-on-LAN targets through one network helper. Keep connection eligibility and platform parsing at their existing boundaries. | Network and wake fixture coverage. | Medium | Validated |
| Capability declarations, resolved capability, live capability evidence and availability | Authored promises, runtime mappings and current-session support. | A declaration cannot prove execution or a live hardware feature. | Keep these representations distinct with one canonical meaning per state. | Runtime resolver, explorer and controller tests. | High | Intentional boundary |
| Per-protocol fixtures and shared transport test doubles | Verify pairing, framing, security, cancellation and command results. | Shared lifecycle assertions may be factored. Wire responses and authorization sequences differ by protocol. | Keep protocol fixtures scoped to their engine and share setup only where its behavior matches. | Tests only. | Low | Intentional boundary |

## Identifier inventory

`RemoteCapability`, `DeviceConnectionState`, `DiscoveryProtocol` and integration verification enums are finite core vocabularies. Driver operation IDs come from core's `RuntimeOperations`. Provider and integration IDs, app IDs, input and channel IDs, and driver profile IDs cross storage or external distribution boundaries as open strings. Existing serialized spellings are compatibility fixtures. Dashboard layout identifiers are authored UI data. Protocol opcodes and vendor payload keys remain engine-owned.

## Baseline validation

Locked dependencies, static analysis, project structure and the dependency audit passed. The complete Dart baseline passed 140 tests, including all four integration parity fixtures. All 133 Flutter tests passed.

## Public API and persisted data

- Dashboard extensions that previously used `TvRemoteDevice` use `GridRemoteViewModel` for dashboard interaction or `TVRemoteBase` for device commands. `RemoteBase` owns its lifecycle methods directly. The Flutter host remains the boundary for widget listeners and command presentation.
- Compatibility selection consumes `DeviceSoftwareInformation` directly. The retired `DriverDeviceEvidence` and `DeviceSoftwareEvidence` projections have no replacement object. `ProfileStage` is the shared bootstrap and identified vocabulary.
- Shared device metadata field names are exported as `DeviceMetadataKeys` from core. Their serialized spellings are unchanged. Legacy cleanup remains in the manager.
- Current device categories and pairing states keep their existing IDs. Saved devices with unfamiliar IDs load as unknown. Integration definitions reject an unfamiliar category.
- A fixture loads the existing `saved-devices.v2`, `dashboards.v2` and `client-key.v2` formats. It verifies the original device/provider/integration IDs, the certificate pin, a dashboard element ID, an unknown dashboard control ID and the original credential key. Existing storage needs no rewrite for this refactor.
- Each driver folder contains its own complete definition. Both LG folders match their original source bytes. Existing signed packages, hashes and bundled seed bytes can be reused.

## Final review

The production scan found one declaration for each audited shared TV model, interface and enum. The duplicate declarations and the obsolete software-evidence projections are gone. The source check and the dependency audit guard the ownership boundary and detect package cycles.

Before and after, `remote_core` has no dependencies on the other workspace packages. `remote_network` and `remote_ui` depend on core. `remote_driver_runtime` depends on core and network. `remote_driver_manager` uses core, network and runtime. The app composes all five. The dependency audit reports 97 reviewed graph entries.

The remaining separate representations serve different boundaries. The Flutter host owns listeners, preview state and command presentation. The manager owns catalog trust and installation. Engines own wire framing and transport responses, including the distinction between authoritative input feedback and absent input data. Every authored driver folder is independently complete.

| Phase | Commit |
| --- | --- |
| Audit and baseline | `d0e3284` |
| Core TV contract | `e9f60fc` |
| Domain models | `7eb9d89` |
| Enums and wire IDs | `7931da3` |
| Metadata contract | `706291d` |
| Shared eligibility and wake rules | `0e6090e` |
| Redundant lifecycle interface | `33b2ddb` |
| Runtime command vocabulary | `b7b759a` |
| UI consumers | `4fc7ae5` |
| Public API and persisted data | `a3a09ba` |
| Restore independent driver definitions | `13269f6` |
| Architecture validation | `5a82a6a` |

Final validation passed with the independent driver folders restored. The run included 143 Dart tests, 135 Flutter tests, 16 driver-tool tests, the lockfile, formatting, static analysis, structure and dependency checks. Android release, iOS simulator debug and macOS debug builds succeeded. The provider fixtures exercise command and subscription parity. Physical-device behavior remains unverified.
