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

The current runtime dependency graph has no package cycles. Network and UI packages depend on core, compiled providers depend on core and network, and the app composes them. The runtime depends on core and network. The manager uses core, network and runtime. The Flutter app compiles independently of the driver source tree.

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

The initial runtime executes a single command over a secure local WebSocket endpoint supplied by the host. A command opens a session, sends validated JSON objects, optionally reads JSON object replies, and closes the connection. The runtime bounds source size, payload nesting, step count, response buffering and total execution time. Configuration cannot supply a URL or certificate pin. The host supplies endpoint and certificate trust through the existing network transport. The fictional-TV fixture substitutes a loopback connector in tests. Drivers that declare authenticated workflows or subscriptions use a persistent session.

## Persistent JSON sessions

Persistent exchanges use a compiled JSON envelope with a request ID and an explicit acknowledgment. A session permits one active exchange at a time and queues up to 16 concurrent calls. A mismatched reply, timeout or cancellation closes that session, and the host can reconnect without replaying a potentially completed command. Subscription requests control delivery of event messages to the host. The pairing code comes from a host callback. Only an acknowledged pairing response may persist a token in the selected driver and device credential scope. The host selects the endpoint, certificate pin and storage scope. This envelope supports the fictional driver protocol; providers with different message formats still need their own compiled or validated protocol adapter.

## Compatibility resolution

The manager checks the existing identified provider ID, known manufacturer, runtime version and operation availability before considering a profile. Within a family, model and firmware evidence rank ahead of generic profiles. Among equally specific releases, package version and then profile revision break ties. Equally supported families require user selection. Connection preparation prefers a compatible installed package by default. Update callers can opt out of that preference. Exact firmware strings are opaque. A firmware or OS range needs a trusted platform comparator, and unknown evidence only matches profiles without that constraint.

The independent [driver authoring tree](../../drivers/README.md) contains the file schemas, an example, and validation and package tooling. The typed loader cross-checks declared capabilities and command files and rejects unexpected entries and symlinks. The package builder archives the exact bytes accepted by the validator in a stable order. The development fixture executes a command loaded from that tree.

## Local lifecycle

The manager initializes from its application-private inventory and package files. It validates package schema, stored identity and runtime support, then activates the enabled records in memory. Installation stages a complete package before committing the inventory, using atomic renames within the same storage directory. A package staged without an inventory commit stays inactive after restart. A structurally damaged active package can fall back to a valid previous version. An offline restart makes no repository requests. The catalog cache preserves the original envelope and ETag for validation by the catalog repository. The lifecycle fixtures use a trusted local repository; remote authentication is the next phase.

## Signed distribution

The repository accepts catalog artifacts from a configured HTTPS origin. It verifies signatures over the exact decoded payload bytes using the host's trusted-key verifier, validates the signed catalog before caching it, and rejects older or conflicting revisions. A verified ETag avoids reloading unchanged metadata. Package downloads are deduplicated and checked against signed size and SHA-256 metadata and a detached package signature before parsing. The ZIP reader accepts the uncompressed, regular-file subset emitted by the builder. It reads bounded text files in memory and rejects unknown paths and entries, so archive names never become disk write paths.

The local HTTP fixture uses ephemeral P-256 keys and verifies signatures with OpenSSL. Platform trust provisioning and application wiring are separate from this repository layer. Package SHA-256 uses the already locked Dart-team `crypto` version 3.0.8. The cached catalog revision protects against remote rollback while the app's private cache remains intact.

## App connection

The app loads its installed driver inventory and verified catalog before using the existing provider registry. Nearby searches refresh metadata concurrently. A new service target learned after a scan starts is used in the next scan. Manual IP runs the existing local probes first and refreshes the catalog when the probes find no match. Managed providers can identify manual IP automatically when their catalog declares an SSDP target. Known Bonjour-only TVs can be selected by provider in manual setup.

The first connection installs only the selected driver. Download progress comes from verified catalog package sizes. Cancelling a connection releases its transfer subscription. The last cancellation aborts the HTTP transfer, and cancellation before inventory activation keeps the package inactive. The app asks which driver to use if more than one family is equally suitable, remembers the selected family on the saved device, and keeps the resolved bundle for the session. The initial generic controller exposes relative volume and power off when their named commands are present. The compiled manufacturer adapters retain their provider IDs and load managed command mappings where available. A background install after the first successful compiled connection makes the mappings available on reconnect.

To enable distribution on Android, iOS or macOS, set `DRIVER_CATALOG_BASE_URL` to the HTTPS base URL with a trailing slash and `DRIVER_TRUSTED_KEYS` to a JSON object keyed by signing key ID. Each value is the Base64 encoding of a 65-byte uncompressed P-256 public point. Private keys remain outside the app. The platform verifies DER-encoded ECDSA signatures over SHA-256.

## Automatic update window

Startup and foreground resume can request a check. The manager persists the next eligible time before contacting the catalog, coalesces concurrent requests, and backs off for 48 hours after a failed check. Successful checks use a 24-hour window. Updates are limited to enabled installed drivers and releases that match every saved device associated with that provider. A manual rollback excludes the rolled-back version from automatic reinstallation. The new package becomes available to the next connection; active controllers retain their bundle.

## Driver Explorer

Settings → Drivers reads the signed cache and the local active and rollback inventory. It displays provider releases, versions, runtime requirements, profile constraints and declared capabilities. Browsing does not issue repository requests. Runtime compatibility applies to the installed app; device support still requires live verification.

See [authoring](../../drivers/README.md), [publishing](publishing.md), and [validation](validation.md) for the commands and release gates.

### Managed television operations

Command IDs are matched to the declared capability before execution. Parameterized JSON send steps use single-field objects such as `{"$argument":"volume"}`. Only bounded scalar arguments can be substituted, and the runtime renders the complete request before opening a socket. Catalogs, volume, playback and content replies are decoded to the shared TV types. Read results feed the controller's state streams. Persistent sessions also feed protocol-originated volume, content and input updates into those streams.

The TV API adapter distinguishes a declaration from a usable command set. A package cannot enable a control solely by listing the capability, and a failed optional read does not revoke independent write operations.

### Software identification workflows

An optional `workflows/identify-software.json` uses the `websocket.request` exchange after any declared authentication and before subscriptions. The reply's `software` object can carry normalized manufacturer, model, hardware model, OS, OS version, software version, firmware version, build and protocol version strings. The host assigns provenance and a timestamp. It preserves only those bounded fields. A TV that explicitly rejects the optional request can still connect. A transport failure follows the normal connection failure path.

The compiled LG adapter preserves its legacy display value and records the firmware components when the response identifies them as firmware. The Android adapter records the authenticated Remote v2 protocol and leaves the OS version unknown. Roku separates the OS version from the build in its [device-info response](https://developer.roku.com/dev/docs/external-control-api). Samsung retains its existing discovery evidence.

Managed controllers select a bootstrap profile from the available device evidence. A fresh software response reruns profile selection within that installed release before the controller reports it is connected. Profiles may list `disabledCapabilities` from the release's declared capabilities. The controller reports and enforces those restrictions, and the app saves the selected profile ID and revision. Profile selection within a release keeps the established transport and credential scope. A different release or connection workflow requires separate activation.
