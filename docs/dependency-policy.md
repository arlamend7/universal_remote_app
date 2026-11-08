# Mandatory Dependency Ownership Policy — Universal Remote

## 1. Dependency Restrictions

The Universal Remote project must follow a strict dependency ownership policy.

**Do not introduce third-party Dart or Flutter packages unless they are published under my verified pub.dev publisher:**

https://pub.dev/publishers/devcom.net.br/packages

This requirement applies to the entire workspace, including production dependencies, transitive dependencies, and development dependencies.

### Allowed

- Dart SDK libraries (`dart:io`, `dart:async`, `dart:convert`, `dart:typed_data`, etc.).
- Official Flutter SDK libraries and bundled tooling.
- Packages owned by the verified publisher `devcom.net.br`.
- New packages implemented and maintained within this repository.
- Native Android and Apple operating-system APIs accessed through Flutter platform channels.

### Restricted

Do not add packages from other pub.dev publishers, even if they are popular, well-maintained, or open-source.

Examples include:

- flutter_riverpod
- provider
- get_it
- flutter_secure_storage
- shared_preferences
- http
- dio
- web_socket_channel
- flutter_blue_plus
- go_router
- auto_route
- freezed
- json_serializable
- logger

The list is illustrative, not exhaustive.

Do not copy third-party package implementations into the repository to circumvent this policy.

Official Flutter testing tools bundled with the SDK are acceptable. If an additional test or development dependency is required, identify it explicitly and distinguish SDK tooling from independently published packages.

Do not silently introduce exceptions.

## 2. Existing Packages Owned by DEVCOM

My verified publisher currently lists these packages:

- `route_definer`
- `flutter_client_factory`
- `flutter_client_factory_widgets`
- `envx`
- `universal_ble_server`

Before implementation:

1. Inspect the current publisher package list.
2. Verify each relevant package's actual public API.
3. Verify SDK compatibility.
4. Inspect its direct and transitive dependencies.
5. Reuse it when it provides the necessary functionality.
6. Do not duplicate its responsibilities unnecessarily.
7. Do not assume a package supports a feature based only on its name.

Use `route_definer` for navigation if its current API meets the application's requirements.

Use `flutter_client_factory` for compatible HTTP communication instead of introducing another HTTP package.

Use `envx` if the application needs its configuration capabilities.

Use `flutter_client_factory_widgets` only when its resource-state adapters provide real value.

Use `universal_ble_server` for future compatible Bluetooth functionality. Do not introduce BLE into the initial LG webOS implementation unnecessarily.

If one of these packages has disallowed transitive dependencies, report that issue and propose a compliant solution rather than ignoring it.

## 3. SDK-First Implementation

Prefer SDK functionality whenever it adequately solves the problem.

### Networking

Use:

- `dart:io` WebSocket for LG webOS communication.
- `dart:io` UDP sockets for SSDP discovery.
- `dart:convert` for JSON.
- `dart:async` for streams, timeouts, and asynchronous coordination.
- `flutter_client_factory` for appropriate HTTP scenarios.

Do not create duplicate HTTP client infrastructure that competes with `flutter_client_factory`.

### State Management

Do not use Riverpod or another third-party state-management package.

Implement application state using appropriate Flutter SDK primitives:

- `ChangeNotifier`
- `ValueNotifier`
- `ListenableBuilder`
- `InheritedNotifier`
- `StreamBuilder`

Use constructor-based dependency injection.

Keep state-management logic separate from device drivers.

### Navigation

Prefer my existing `route_definer` package.

Do not introduce another routing package.

### Credential Storage

Implement secure storage through native platform integrations.

For iOS/macOS:

- Use Apple Keychain APIs.

For Android:

- Use Android Keystore to protect encryption keys.
- Store credentials encrypted using an appropriate native authenticated-encryption mechanism.

Expose a platform-independent `CredentialStore` interface.

Do not implement custom cryptographic algorithms.

Do not store LG pairing keys as plaintext in application preferences.

### Local Preferences

Implement a minimal preferences abstraction using native platform facilities when required.

Do not introduce `shared_preferences`.

Separate ordinary preferences from credentials.

### Logging

Implement a lightweight structured logging interface using SDK functionality.

Support configurable log levels and redaction of sensitive information.

Never log pairing keys, security tokens, or authentication payloads containing credentials.

## 4. Native Platform Integration

Use Flutter platform channels when access to native operating-system functionality is required.

Keep native integrations modular so they can eventually become separate plugins maintained under DEVCOM.

Potential future modules include:

- Secure storage.
- Native infrared transmission.
- Platform-specific network discovery.
- Network state monitoring.
- Bluetooth functionality not already covered by `universal_ble_server`.

Do not implement these future modules until they are needed.

## 5. Architecture Requirements

Preserve the original modular architecture:

- `remote_core`: pure Dart device contracts and capabilities.
- `remote_network`: pure Dart communication and discovery.
- `remote_lg_webos`: pure Dart LG protocol implementation.
- `universal_remote_app`: Flutter user interface and native integrations.

The architecture must remain extensible to other protocols and devices.

Avoid coupling the core to:

- Flutter widgets.
- LG webOS.
- A particular operating system.
- A specific network transport.
- Any third-party state-management implementation.

## 6. Dependency Verification

After implementing each milestone:

1. Inspect every package's `pubspec.yaml`.
2. Inspect the complete resolved dependency graph.
3. Verify which dependencies come from the Dart/Flutter SDK.
4. Verify which dependencies are published under `devcom.net.br`.
5. Identify any external packages that were pulled in transitively.
6. Remove or replace prohibited dependencies where feasible.
7. Report unavoidable exceptions before relying on them.

Do not assume that an existing DEVCOM package is dependency-free without inspecting its resolved dependency graph.

Use the current installed Flutter and Dart tooling to determine exact compatible versions.

## 7. Reusable Package Strategy

When implementing functionality that is reusable outside Universal Remote, consider extracting it into its own package.

However:

- Do not create a package solely to satisfy an architectural diagram.
- Do not publish unfinished packages.
- Keep small implementation details internal when appropriate.
- Extract packages when they have clear responsibilities, stable interfaces, and independent value.

Potential future DEVCOM packages include:

- Network service discovery.
- Device capability modeling.
- Secure platform storage.
- Infrared command encoding.
- Infrared learning.
- Universal remote protocol integrations.

Use meaningful names and verify package-name availability before planning publication.

## 8. Testing Policy

Use official SDK-provided testing functionality where available.

Build deterministic tests for:

- Core device abstractions.
- WebSocket connections.
- SSAP registration.
- LG command serialization.
- Request/response correlation.
- Pairing lifecycle.
- SSDP parsing.
- Capability resolution.
- Flutter UI behavior.

Use in-process fake servers and test doubles rather than introducing third-party mocking libraries.

Clearly disclose any testing dependency that falls outside the ownership policy.

## 9. Implementation Priorities

Implement in this order:

1. Dart workspace and package structure.
2. DEVCOM-compatible dependency configuration.
3. Pure Dart core models and interfaces.
4. WebSocket transport using `dart:io`.
5. LG SSAP protocol and pairing.
6. Secure native credential storage.
7. LG volume and navigation controls.
8. Flutter UI using SDK state management and `route_definer`.
9. SSDP discovery.
10. Tests, security checks, documentation, and CI.

Preserve the LG-first development scope.

## 10. Mandatory Final Report

At the end of the implementation, provide:

- All created packages.
- Every direct and transitive dependency.
- The publisher or source of each dependency.
- Any violations of the dependency ownership policy.
- Features implemented using DEVCOM packages.
- Features implemented directly using Dart/Flutter SDK APIs.
- Native platform integrations created.
- Tests executed and results.
- Build results.
- Hardware-dependent limitations.
- Suggested reusable DEVCOM packages for future extraction.

**The goal is to own and maintain the application's reusable architecture without depending on independently maintained third-party Dart/Flutter libraries.**

Start implementing the LG webOS MVP while respecting these restrictions.