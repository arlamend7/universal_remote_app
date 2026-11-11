> Historical specification. `AGENTS.md` and `docs/architecture.md` are current: state management uses AppBootstrap/AppDependencies with constructor injection and ValueNotifier/ListenableBuilder, not Riverpod.

# Project: Universal Remote — Flutter & Dart Ecosystem

You are a senior Flutter/Dart engineer, software architect, and technical lead.

Your task is to **design and implement a production-quality Universal Remote ecosystem**, consisting of a Flutter application and reusable Dart packages.

Do not stop at documentation or architecture proposals. Create the project, implement the first working integration, add tests, and ensure the project can be built and analyzed.

Use the requirements below as the primary specification.

## 1. Project Vision

Build a cross-platform universal remote application that can eventually control the maximum practical number of compatible devices, including:

- Smart TVs: LG webOS, Samsung Tizen, Android/Google TV, Roku, Apple TV.
- Air conditioners: LG, Samsung, Daikin, Midea, Gree, and traditional infrared-controlled units.
- Streaming devices and media players.
- Soundbars, speakers, audio receivers, and projectors.
- Smart lights, fans, heaters, blinds, and other home automation devices.
- Computers and other devices with accessible control protocols.

**Phase 1 must implement LG webOS only.**

However, the architecture must allow additional device categories, manufacturers, protocols, transports, and hardware gateways without restructuring the core.

Do not create empty packages for integrations that have not yet been implemented.

## 2. Engineering Principles

Follow these principles throughout development:

1. SOLID and dependency inversion.
2. Clean Architecture where it provides clear value.
3. Composition over inheritance.
4. Interface segregation.
5. Capability-based device control.
6. Plugin/provider-based extensibility.
7. Strong typing and null safety.
8. Asynchronous, event-driven communication.
9. Secure credential storage.
10. Local-first functionality.
11. Testability and dependency injection.
12. Clear error reporting and lifecycle management.
13. Reusable packages independent of Flutter wherever possible.
14. Minimal unnecessary abstractions and dependencies.
15. Comprehensive documentation and practical examples.

Avoid overengineering. Introduce abstractions that have a clear purpose and concrete use.

## 3. Technology Stack

Use:

- Latest compatible stable Flutter and Dart SDKs.
- Dart Pub Workspaces for the monorepo.
- Flutter for the application UI.
- Riverpod for Flutter application state management.
- Pure Dart for core domain interfaces and protocol implementations whenever possible.
- `dart:io` and suitable adapters for socket communication.
- WebSocket for LG webOS SSAP.
- UDP/SSDP for automatic network discovery.
- `flutter_secure_storage` for client-key persistence.
- `test` and `flutter_test` for automated tests.
- GitHub Actions for CI.

Use current package versions compatible with the installed SDK. Verify APIs against installed dependencies and authoritative documentation.

Do not add a backend, database, cloud service, authentication server, or analytics system unless required by a concrete Phase 1 feature.

## 4. Required Monorepo Structure

Create the following structure, adapting individual filenames when beneficial:

```text
universal_remote/
├── apps/
│   └── universal_remote_app/
│       ├── lib/
│       │   ├── app/
│       │   ├── core/
│       │   ├── features/
│       │   │   ├── discovery/
│       │   │   ├── devices/
│       │   │   ├── pairing/
│       │   │   ├── remote/
│       │   │   └── settings/
│       │   └── main.dart
│       └── test/
│
├── packages/
│   ├── remote_core/
│   │   ├── lib/src/
│   │   │   ├── devices/
│   │   │   ├── capabilities/
│   │   │   ├── discovery/
│   │   │   ├── commands/
│   │   │   ├── providers/
│   │   │   └── errors/
│   │   └── test/
│   │
│   ├── remote_network/
│   │   ├── lib/src/
│   │   │   ├── websocket/
│   │   │   ├── ssdp/
│   │   │   └── transport/
│   │   └── test/
│   │
│   └── remote_driver_runtime/
│       ├── lib/src/
│       │   ├── adapters/
│       │   ├── ssap/
│       │   ├── remote_v2/
│       │   ├── samsung/
│       │   └── ecp/
│       └── test/
│
├── docs/
│   ├── architecture.md
│   ├── protocols.md
│   ├── capability-model.md
│   ├── lg-webos.md
│   ├── adding-a-provider.md
│   ├── security.md
│   └── roadmap.md
│
├── .github/workflows/
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

Configure workspace-local dependencies correctly. The root should coordinate dependency resolution without introducing unnecessary coupling.

## 5. Core Architecture

Implement a device model independent of brands.

Each device must expose appropriate identity and metadata, including:

- Stable device identifier, where available.
- Display name.
- Manufacturer.
- Model.
- Device category.
- Available network endpoints.
- Supported and available capabilities.
- Connection state.
- Pairing state, where applicable.

Support these device categories in the domain model:

- Television.
- Air conditioner.
- Media player.
- Speaker.
- Light.
- Fan.
- Projector.
- Generic/unknown device.

Do not implement their manufacturer integrations yet.

### Capability model

Create independent capability interfaces for:

- Power.
- Volume.
- Navigation.
- Media playback.
- Application launching.
- Input selection.
- Channel control.
- Pointer interaction.
- Climate control.
- Lighting control.

Only implement functionality needed by LG in Phase 1. Other capability contracts may be defined if their API is already clear, but avoid speculative complexity.

Devices must expose only capabilities they actually support.

Prefer typed capability controllers instead of a large interface containing every possible command.

An ideal consumer experience should resemble:

```dart
final result = await discoveryManager.discover();
final controller = registry.createController(result.devices.first);
await controller.connect();

if (controller is TVRemoteBase && controller.supports(RemoteCapability.volume)) {
  await controller.volumeUp();
}
```

This is illustrative; design the final API to be coherent and type-safe.

### Capability metadata

Design a way to record where capability information came from:

- Device advertisement.
- Standardized protocol discovery.
- Manufacturer driver.
- Device profile/database.
- Learned command.
- User configuration.

Distinguish between:

- Advertised capabilities.
- Known driver capabilities.
- Verified available capabilities.
- Unsupported or unavailable capabilities.

Do not assume that every advertised command is supported by every firmware.

## 6. Device Provider System

A `ProviderIdentifier` declares discovery targets and interprets raw protocol evidence.
A `ProviderDefinition` binds the identifier to a typed controller factory and
optional manual setup, wake and connection policies.

`DiscoveryManager` coordinates protocol searches, timeouts, failure isolation
and identity resolution. `ProviderRegistry` resolves a saved profile to its
exact integration. Controllers own pairing, commands and session state.
- Supporting manually configured devices.

Never use IP addresses alone as permanent device identities.

The initial provider list must contain only LG webOS.

Document how a future developer could add a Samsung, Roku, Matter, or infrared provider without changing core implementation details.

## 7. Communication Layer

Implement reusable transport abstractions.

For Phase 1, support:

- WebSocket transport.
- UDP-based SSDP discovery.

WebSocket transport requirements:

- Connect and disconnect.
- Send and receive messages.
- Expose connection state.
- Handle socket errors.
- Handle timeouts.
- Support reconnection at the device-client layer.
- Support request/response correlation in the application protocol layer.
- Allow test doubles or in-memory fake servers.

Keep transport framing separate from manufacturer command formats.

Architecture must permit future transports such as:

- HTTP/HTTPS.
- Raw TCP/UDP.
- Bluetooth LE.
- Bluetooth Classic, where accessible.
- Native infrared emitters.
- IR/RF hubs.
- MQTT.
- Matter.
- Zigbee/Z-Wave gateways.
- HDMI-CEC bridges.
- Manufacturer cloud APIs.

Do not implement those future transports yet.

Avoid relying on unsupported mobile-platform APIs.

## 8. LG webOS — First Real Integration

Implement the first complete device provider for compatible LG webOS televisions.

### 8.1 Discovery

Implement SSDP-based discovery.

Discover and identify compatible LG webOS televisions using reliable device information.

Return:

- Device name.
- Manufacturer.
- Model, when available.
- Address.
- Relevant advertised identifiers.
- Discovery metadata.

Include a manual IP connection option.

Manual IP connection must work independently of SSDP because some networks block multicast traffic.

### 8.2 WebSocket

Implement LG's SSAP connection using commonly supported endpoints:

- Secure WebSocket on port 3001.
- Legacy WebSocket on port 3000 where supported and permitted.

Prefer secure communication.

Handle device-specific TLS certificate validation without globally disabling certificate verification.

Do not silently downgrade to insecure communication. Clearly identify compatibility/security tradeoffs.

### 8.3 Pairing

Implement the registration workflow:

1. Open connection.
2. Send LG registration request.
3. Request necessary permissions.
4. Handle TV pairing prompt.
5. Process registration response.
6. Extract authorized client key.
7. Save key securely using an application-provided credential store.
8. Reuse key on subsequent connections.
9. Handle rejected or revoked keys.
10. Support re-pairing and forgetting a device.

Use version-appropriate LG registration manifest details based on verified implementations or specifications.

Do not assume one manifest works on every firmware.

Never log pairing keys or credentials.

### 8.4 SSAP Command Client

Implement a reusable SSAP request client with:

- Unique request IDs.
- JSON serialization.
- Response correlation.
- Error interpretation.
- Request timeouts.
- Concurrent requests.
- Subscription handling.
- Proper cleanup on disconnect.

A failed command must not leave unresolved pending futures indefinitely.

### 8.5 Volume Control

Support:

- Volume up.
- Volume down.
- Set volume.
- Mute/unmute.
- Read current volume, where supported.
- Subscribe to volume changes, where supported.

### 8.6 Navigation

Support:

- Up.
- Down.
- Left.
- Right.
- Enter/OK.
- Back.
- Home.

Implement LG's pointer input socket separately from the main SSAP socket.

Use correct command formatting, including the required message separators.

Prepare this component for future mouse movement, pointer and scroll controls.

### 8.7 Power

Support:

- Power off through a compatible SSAP operation.
- Wake-on-LAN power-on where supported.

Do not imply that power-on is universally supported.

Store a usable MAC address only when reliably identified or explicitly configured.

Provide clear feedback when network wake is unavailable.

### 8.8 Applications and Inputs

Support, where available:

- List installed TV applications.
- Launch an installed application by its actual identifier.
- List available TV inputs.
- Switch to a selected input.
- Query relevant current state.

Do not hardcode Netflix, YouTube, or other application IDs across all devices.

### 8.9 Lifecycle

Handle:

- TV unavailable.
- Wi-Fi disconnected.
- TV turned off.
- App background/foreground transitions.
- Socket unexpectedly closed.
- Reconnection.
- Stale pairing key.
- Unsupported command.
- Permission rejection.
- Duplicate discovery responses.

Provide meaningful errors rather than generic exceptions.

## 9. Flutter Application

Build a polished, responsive application with a clean design.

Use Material 3 with support for dark and light themes.

The UI must not be coupled directly to LG-specific command names.

Implement the following screens.

### Device Discovery

- Search for devices.
- Display discovered LG TVs.
- Refresh discovery.
- Show discovery/loading/errors.
- Provide manual IP entry.
- Select a device.

### Pairing

- Explain that approval is required on the television.
- Display pairing progress.
- Handle acceptance, rejection, timeout, and failure.
- Retry or cancel pairing.
- Never display or expose the client key.

### Saved Devices

- List previously paired devices.
- Show online/offline/connecting state.
- Connect to a saved device.
- Rename a local device profile.
- Forget a device and its stored credentials.

### Remote Control

Build a functional remote UI with:

- Power.
- Directional navigation.
- OK.
- Back.
- Home.
- Volume up/down.
- Mute.
- Applications.
- Input selection.
- Connection status.

Only show enabled controls for supported capabilities.

Do not make the UI look like a generic debugging tool. It should be practical to use as a daily TV remote.

### Settings

Include:

- Theme selection.
- Device information.
- Connection details.
- Re-pair or forget device.
- Diagnostic logging toggle, with sensitive data redacted.

Persist only necessary preferences.

## 10. State Management

Use Riverpod in the Flutter application.

Separate:

- Device discovery state.
- Selected device state.
- Pairing state.
- Connection state.
- Remote-control state.
- Saved-device state.

Controllers must correctly dispose of streams and resources.

Avoid placing protocol logic inside widgets or Riverpod providers.

Riverpod should coordinate the application, not implement SSAP.

## 11. Platform Support

Phase 1 should target:

- Android.
- iOS.

Make the core packages platform-independent where possible.

Prepare the design for:

- Windows.
- macOS.
- Linux.

Configure required Android and iOS network permissions.

Account for:

- iOS local-network privacy declarations.
- iOS multicast networking restrictions and entitlement requirements.
- Android multicast discovery behavior.
- Network changes.
- App lifecycle transitions.

Do not claim that background connectivity or network wake works universally across mobile platforms.

## 12. Security Requirements

Security must be considered from the beginning.

Implement:

- Secure persistence of pairing credentials.
- No credentials in debug logs.
- No hardcoded keys.
- Narrowly scoped TLS certificate handling.
- No global trust-all-certificate overrides.
- Explicit user pairing.
- Device-local network communication by default.
- Proper error handling for rejected authorization.

Do not expose a control server to the internet.

Do not attempt to bypass manufacturer pairing or authentication.

## 13. Automated Tests

Create meaningful tests for each package.

### remote_core

Test:

- Capability resolution.
- Provider registration.
- Provider selection.
- Discovery aggregation.
- Duplicate-device handling.
- Provider failures.
- Connection lifecycle contracts.

### remote_network

Test:

- WebSocket connect/disconnect.
- Message sending and receiving.
- Connection failures.
- Timeouts.
- SSDP message parsing.
- Malformed discovery responses.
- Discovery cancellation and cleanup.

### remote_driver_runtime · LG webOS adapter

Use a fake/mock LG WebSocket server to test:

- Registration requests.
- Successful pairing.
- Rejected pairing.
- Saved-key reuse.
- Revoked keys.
- SSAP request serialization.
- Response ID correlation.
- Error responses.
- Concurrent commands.
- Pointer command formatting.
- Subscription behavior.
- Disconnect/reconnect scenarios.

### Flutter

Test:

- Discovery screen.
- Pairing states.
- Dynamic capability-based remote UI.
- Disabled and unsupported commands.
- Connection errors.
- Saved-device selection.

No physical TV should be required to run the automated test suite.

Provide a separate manual hardware-test checklist for real LG televisions.

## 14. Documentation

Create practical documentation.

### README.md

Explain:

- Project purpose.
- Features.
- Supported devices.
- Requirements.
- Workspace setup.
- How to run the Flutter application.
- How to run tests.
- How to connect an LG webOS television.
- Known limitations.
- Roadmap.

### architecture.md

Explain:

- Package responsibilities.
- Dependency direction.
- Provider registry.
- Device lifecycle.
- Capability model.
- Transport abstraction.

Include Mermaid diagrams.

### protocols.md

Explain the difference between:

- Device discovery.
- Capability discovery.
- Command discovery.
- Pairing.
- Transport.
- Application protocol.

Document the design for future technologies, including IR, RF, Bluetooth, Matter, MQTT, Zigbee, Z-Wave, and cloud APIs.

### lg-webos.md

Explain:

- SSDP discovery.
- SSAP WebSocket connection.
- Pairing.
- Client keys.
- Supported commands.
- Pointer connection.
- Power-on limitations.
- Firmware compatibility.

### adding-a-provider.md

Provide a concrete guide for implementing another device provider.

Use a fictional example or a small test provider without creating unnecessary production packages.

### roadmap.md

Document planned integrations, their likely transports, hardware requirements, and technical limitations.

## 15. CI/CD

Create a GitHub Actions workflow that:

1. Installs Flutter and Dart.
2. Restores dependencies.
3. Verifies formatting.
4. Runs static analysis.
5. Runs Dart package tests.
6. Runs Flutter tests.
7. Builds an Android debug APK where the CI environment supports it.

Do not publish packages or deploy releases automatically.

Keep release and publishing workflows for later.

## 16. Coding Standards

Follow these standards:

- Dart naming conventions.
- Small, focused files.
- Public API documentation comments.
- No unnecessary `dynamic`.
- Meaningful errors.
- Proper cancellation and disposal.
- Avoid blocking operations on the main isolate.
- Avoid duplicated command strings.
- Prefer immutable models.
- Avoid global mutable state.
- Use dependency injection through constructors.
- Keep business logic separate from Flutter widgets.
- Do not introduce abstractions without a concrete need.

Use comments to explain non-obvious protocol behavior, not trivial code.

## 17. Implementation Sequence

Work in this order:

### Milestone 1 — Foundation

- Create monorepo.
- Configure Pub Workspaces.
- Create Flutter application.
- Implement `remote_core`.
- Define device, provider and capability contracts.
- Add initial core unit tests.

### Milestone 2 — Networking

- Implement WebSocket transport.
- Implement request lifecycle utilities.
- Implement SSDP discovery and parsing.
- Add network tests.

### Milestone 3 — LG webOS

- Create LG provider.
- Implement manual IP connection.
- Implement SSAP registration and pairing.
- Implement client-key persistence integration.
- Implement volume commands.
- Implement pointer socket and navigation.
- Implement power-off.
- Implement applications and input selection where available.
- Add LG protocol tests.

### Milestone 4 — Flutter UI

- Build discovery screen.
- Build pairing screen.
- Build saved-device screen.
- Build remote-control screen.
- Integrate Riverpod.
- Handle connectivity and errors.
- Add widget tests.

### Milestone 5 — Stability

- Improve reconnect behavior.
- Add device and capability validation.
- Ensure credentials are protected.
- Complete documentation.
- Add CI.
- Run formatting, analysis, tests and builds.
- Resolve all issues found.

## 18. Definition of Done

The first working release is complete when:

- The Flutter application launches on Android and iOS.
- An LG webOS TV can be discovered on a compatible network.
- Manual IP connection works.
- The user can approve pairing on the TV.
- The client key is stored securely.
- Subsequent connections reuse the key.
- Volume and mute work.
- Navigation works.
- Power-off works on supported TVs.
- Applications and inputs work where supported.
- Unsupported commands are handled appropriately.
- Socket failures do not crash the app.
- Multiple providers can be registered without changing the core.
- Tests pass.
- Static analysis passes.
- The project is documented.
- CI is configured.

Hardware-dependent behavior must be marked as unverified until tested on a real LG television.

## 19. Future Extensibility

Ensure the architecture can eventually support the following without breaking existing public APIs:

- Samsung Tizen driver.
- Android/Google TV driver.
- Roku driver.
- Apple TV driver.
- Midea and other smart AC drivers.
- Infrared command encoding.
- Infrared learning through compatible hardware.
- RF gateway adapters.
- Bluetooth LE device drivers.
- Matter controller integration.
- MQTT discovery conventions.
- Zigbee and Z-Wave gateways.
- Home Assistant integration.
- HDMI-CEC bridges.
- Custom device profiles.
- User-configurable remote layouts.
- Macros and automation scenes.

These are architectural objectives, not Phase 1 implementation requirements.

## 20. Execution Instructions

You are authorized to create, edit, and organize the files needed for this project in the current repository.

Before implementation:

1. Inspect the repository and installed Flutter/Dart environment.
2. Preserve existing user files if the repository is not empty.
3. Establish the minimum viable architecture.
4. Identify any platform or protocol compatibility concerns.
5. Begin implementation.

During implementation:

- Make actual code changes.
- Run available commands and tests.
- Fix errors rather than leaving known broken code.
- Do not leave placeholder methods pretending to work.
- Do not hardcode mock devices into production discovery.
- Keep mock implementations within tests and development previews.
- Do not invent LG protocol operations.
- Clearly distinguish implemented, partially implemented and future features.
- Continue through the implementation milestones without stopping after only generating a plan.

If an external dependency, physical television or unavailable tool blocks verification, implement and test everything that can be verified locally, and document the exact remaining manual verification steps.

At completion, report:

1. Architecture and created packages.
2. Implemented features.
3. Tests executed and their results.
4. Build and analysis results.
5. Hardware-dependent items not yet verified.
6. Known limitations.
7. Exact commands to run the application.
8. Next development priorities.

**Start implementing now. The immediate priority is a working LG webOS remote built on a reusable, extensible Dart architecture.**