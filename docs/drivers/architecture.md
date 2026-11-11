# Dynamic TV drivers

The application currently creates compiled providers in [AppBootstrap](../../apps/universal_remote_app/lib/app/app_bootstrap.dart). Each registers a `ProviderDefinition` with an identifier, a controller factory, and optional manual setup, wake and connection policies. Nearby search uses the existing discovery manager to collect observations and resolve provider profiles. Manual connection uses provider-specific setup and the same connection controller. Controllers report capabilities through the existing typed remote interfaces.

## Package boundaries

| Package | Responsibility |
| --- | --- |
| `remote_core` | Transport-independent device, provider, controller and driver contracts. Preserve persisted provider and device IDs. |
| `remote_network` | Device discovery, observations, bounded transport sessions, certificate trust and Wake-on-LAN. Keep existing identity correlation through `DeviceIdentifierResolver`. |
| `remote_driver_runtime` | Validate and execute declarative workflows through an allowlist of compiled operations. Adapt runtime controllers to existing provider contracts. |
| `remote_driver_manager` | Resolve compatible versions and profiles. Verify, install, activate, update and roll back driver packages. |
| `remote_ui` | Present typed catalog and capability data. Catalog browsing reads metadata without downloading driver packages. |
| `universal_remote_app` | Compose dependencies, connect lifecycle events, supply local storage and credentials, and use the existing provider registry. |

The current runtime dependency graph has no package cycles. Network and UI packages depend on core, compiled providers depend on core and network, and the app composes them. The planned runtime depends on core and network. The planned manager may use core, network and runtime. The Flutter app compiles independently of the driver source tree.

## Lifecycle and trust

Load installed packages and the last verified catalog from local storage. Nearby discovery starts immediately and refreshes catalog metadata concurrently. Selection or manual IP setup resolves compatible candidates from observed evidence, preferring a working local driver. Download only the chosen package when needed. Package versions, runtime versions, platform versions and firmware comparisons have separate semantics.

Authenticate signed catalogs and reject older revisions. Authenticate and hash package bytes before extracting into staging, validate the extracted files, and promote the verified installation atomically. Keep the previous version for rollback. An active controller keeps its selected driver version for the session. Automatic update checks use persisted timestamps and run when the app is active and a check is due.

Drivers contain data and can invoke only operations shipped in the app. Restrict endpoints to the selected device and approved services, bound execution and I/O, and scope credentials to the selected provider and device. Keep certificate trust and pairing in compiled code where the protocol requires it. GitHub Pages distributes public artifacts. Signing keys stay in the protected publishing environment.

## Current storage

Device profiles and dashboard data use the application preferences adapter. Pairing secrets use the separate protected storage adapter and `CredentialStore`, with a session wrapper on macOS. Keep all existing storage keys valid during migration. Driver storage will use its own inventory and versioned installation paths.

## Core metadata format

Core schema version 1 defines stable numeric `major.minor.patch` package and runtime versions. A runtime requirement uses `>=minimum` with an optional exclusive `<upper` bound. Prerelease versions are currently unsupported. Profile revisions are positive integers. Platform OS and firmware evidence are separate opaque strings, interpreted later by the manager's comparison strategy. The metadata decoder rejects unknown fields and operation IDs. Recognizing an operation ID in core does not establish that a particular runtime build implements it.

The shared WebSocket transport supports bounded, cancellable handshakes and exact certificate pins. It owns the connection after a successful handshake. Compatibility inputs are projected from already identified profiles, with absent manufacturer, model and version evidence represented as unknown. Discovery protocol selection and device identity correlation continue to use the existing registry and resolver.

## Runtime foundation

The initial runtime executes a single command over a secure local WebSocket endpoint supplied by the host. A command opens a session, sends validated JSON objects, optionally reads JSON object replies, and closes the connection. The runtime bounds source size, payload nesting, step count, response buffering and total execution time. Configuration cannot supply a URL or certificate pin. The host supplies endpoint and certificate trust through the existing network transport. The fictional-TV fixture substitutes a loopback connector in tests. Persistent sessions, pairing and subscriptions belong to the next phase.

## Persistent JSON sessions

Persistent exchanges use a compiled JSON envelope with a request ID and an explicit acknowledgment. A session permits one active exchange. A mismatched reply, timeout or cancellation closes that session, and the host can reconnect without replaying a potentially completed command. Subscription requests control delivery of event messages to the host. The pairing code comes from a host callback. Only an acknowledged pairing response may persist a token in the selected driver and device credential scope. The host selects the endpoint, certificate pin and storage scope. This envelope supports the fictional driver protocol; providers with different message formats still need their own compiled or validated protocol adapter.

## Compatibility resolution

The manager checks the existing identified provider ID, known manufacturer, runtime version and operation availability before considering a profile. Within a family, model and firmware evidence rank ahead of generic profiles. Among equally specific releases, package version and then profile revision break ties. Equally supported families require user selection. Connection preparation prefers a compatible installed package by default. Update callers can opt out of that preference. Exact firmware strings are opaque. A firmware or OS range needs a trusted platform comparator, and unknown evidence only matches profiles without that constraint.
