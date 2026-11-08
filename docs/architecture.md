# Architecture

The current folder map and readability conventions are in
[contexts/flutter/project-structure.md](contexts/flutter/project-structure.md) and
[contexts/architecture/readability-rules.md](contexts/architecture/readability-rules.md).
Navigation uses DEVCOM route_definer 4.0.0 at a verified, pinned Git revision.

Universal Remote is a five-package Pub workspace. Core and protocol code is pure
Dart. The application and shared remote UI import Flutter. Native storage plugins remain in the application.

```mermaid
flowchart TD
  Bootstrap[AppBootstrap] --> Dependencies[AppDependencies]
  Dependencies --> Screens[Flutter screens]
  Screens --> State[Injected controllers and ValueNotifiers]
  State --> Registry[ProviderRegistry]
  Registry --> LG[remote_lg_webos]
  LG --> Core[remote_core]
  LG --> Network[remote_network]
  State --> Storage[ApplicationStorage and CredentialStore]
  Storage --> Native[flutter_secure_storage]
```

## Injection and ownership

Following the Kap Games approach, `AppBootstrap.initialize` is the composition
root. It assembles the credential adapter, provider registry, saved-device
repository, discovery/connection/settings controllers, and returns a concrete
`AppDependencies` object. The root app and screens receive it through their
constructors. Domain services also receive their dependencies through constructors.
There is no Riverpod, GetIt, global service locator, or hidden dependency lookup.

`ValueNotifier` owns UI state; `ValueListenableBuilder` and `ListenableBuilder`
render it. Discovery, selected device, connection/pairing, volume/command progress,
saved profiles, and settings have separate observable values. Protocol state
remains in the LG client. Tests replace storage, providers, and transports. Bootstrap uses native preferences
for profiles/settings and a separate secure adapter only for pairing keys. It does
not access Keychain during normal startup; older profiles migrate on explicit request.

The app owns `AppDependencies` and disposes it once. Cleanup futures are reused
so callers can await an in-progress disposal. A DeviceSession owns its driver and state subscription; VolumeObserver owns
volume updates, and RemoteCommandController owns command progress/error handling.
LG capability controllers depend on a command channel or pointer connection
rather than their device owner. Device clients own SSAP and pointer
sockets, request timers, subscription timers, reconnect timers, and subscriptions.
Discovery owns its UDP socket and always releases the native multicast lock.

## Provider registry

Providers declare an identifier, compatibility predicate, cancellable discovery,
and a controller factory. The registry runs discovery concurrently, limits each
provider's work, isolates failures, and publishes deduplicated results as
providers finish. LG also emits results when SSDP advertisements arrive.
Timeouts signal cooperative cancellation; a noncooperative future cannot be
forcibly stopped by Dart, so providers must honor the token.

LG is the only production provider. Manual profiles use cryptographically random
local profile IDs; SSDP devices use advertised UUIDs. IP addresses are mutable
endpoints. Separate manual and advertised profiles are not automatically merged
without reliable identity evidence. Rediscovering a saved UUID preserves its
local name, certificate configuration, and explicitly chosen transport.

```mermaid
stateDiagram-v2
  [*] --> Disconnected
  Disconnected --> Connecting: user selects TV
  Connecting --> Pairing: SSAP socket open
  Pairing --> Connected: registered and capability checks complete
  Pairing --> Disconnected: rejection / timeout / cancellation
  Connected --> Reconnecting: unexpected socket loss
  Reconnecting --> Connected: authorized reconnect
  Reconnecting --> Disconnected: bounded retries exhausted
  Connected --> Disconnected: background / user disconnect / dispose
```

## Capabilities

`TVRemoteBase` and `ACRemoteBase` expose every command directly (for example
`volumeUp()`, `press(key)`, `setTargetTemperature()`); core does not care how a
provider splits the work. Unsupported commands throw `RemoteException`, and
`supports(RemoteCapability)` reports driver evidence. The LG driver delegates to
internal per-feature controllers.
Evidence records source and availability separately; see capability-model.md.
The UI knows these interfaces and contains no SSAP URI strings.

## Remote dashboard

Remote and Devices share the existing indexed main shell. The live remote and
editor use a single grid, with a starter grid for devices without an active
saved dashboard. `packages/remote_ui` separates the editor, catalog,
renderer and shared `UniversalRemoteItem`.

The `remote_ui` workspace package owns item definitions, catalog eligibility,
geometry and the shared item shell. Standard, TV and AC definitions share a
registry. Provider lifecycle contracts remain in `remote_core`. Dashboards use a
separate local repository.
Saved grids contain serializable identifiers and configuration. Dart callbacks
are supplied by the compiled definitions. See [the migration plan](migration-plan.md)
for the remaining control families and storage work.

## Transport boundary

`TextTransport` is an injectable text-frame connection. `IoWebSocketTransport`
uses the SDK WebSocket and exposes socket state. SSAP owns JSON framing, request
IDs, registration, subscriptions, and correlation. Navigation uses a different
socket and blank-line-delimited text. SSDP and WOL are separate UDP responsibilities.

## Provider-owned policy and grouped core contracts

`remote_core` exposes `RemoteBase`, `TVRemoteBase` and `ACRemoteBase` in
three files. Each file groups its capability interfaces and value types with
the corresponding base. Shared device records and provider interfaces are
grouped in `device.dart` and `provider.dart`. Older controller type names
remain available as aliases. Provider implementation files still follow
the one-type-per-file rule.

`ProviderRegistry.connect(device)` opens a session. `turnOn(device)` sends
wake once and retries the connection through the same workflow used by the
app's observable session adapter. The provider classifies startup errors and
owns connection settings, legacy category mapping, and certificate policy.
Core owns discovery identity matching and optional wake-address learning.
The app supplies the platform address lookup and profile persistence callbacks.

The grid editor's draft, sizing, undo/redo and save workflow live in
`remote_ui`. It calls the app's `DashboardStore` adapter for persistence.
