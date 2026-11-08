# Adding a provider

1. Implement `DeviceProvider` with a unique identifier and an explicit compatibility
   predicate. Use reliable advertised IDs or persisted profile IDs, never an IP as
   a permanent identity.
2. Implement cancellable discovery. Bound network work, close owned resources in
   finally blocks, and avoid changing unrelated providers' state.
3. Implement a `DeviceController` with lifecycle state/events and typed capability
   controllers. Pairing and authorization belong here, not in widgets.
4. Keep reusable code pure Dart; inject transports and credential storage.
5. Register the provider in AppBootstrap. The registry implementation does not
   need modification. Add device-specific setup fields only if needed.
6. Test selection, discovery failures/timeouts, deduplication, authorization,
   protocol serialization, cancellation, unsupported controls, and disposal.
7. Re-audit dependency publishers, public APIs, installed SDK compatibility, and
   the full resolved graph before updating the reviewed dependency snapshot.

A hypothetical provider could implement this shape without changing core:

```dart
class ExampleProvider implements DeviceProvider {
  ExampleProvider(this.discovery, this.controllerFactory);
  final Future<List<RemoteDevice>> Function(DiscoveryCancellation) discovery;
  final DeviceController Function(RemoteDevice) controllerFactory;
  @override
  String get id => 'example.device';
  @override
  bool supports(RemoteDevice device) => device.providerId == id;
  @override
  Future<List<RemoteDevice>> discover(DiscoveryCancellation token) => discovery(token);
  @override
  DeviceController createController(RemoteDevice device) => controllerFactory(device);
}
```

This is a documentation example, not an empty production integration. Samsung,
Roku, Matter, and IR providers should use their own documented discovery/pairing
and transport implementations. Contract tests in remote_core demonstrate multiple
providers, failure isolation, and controller disposal.


The Android TV provider uses Flutter's pure Dart `multicast_dns` 0.3.3+1 for
local discovery and Bouncy Castle's `pointycastle` 4.0.0 for RSA key generation,
signing, ASN.1, and SHA-256. Both are pinned in the workspace lockfile. The
provider accepts a self-signed peer only during the code-authenticated pairing
exchange. Subsequent sessions check the exact certificate fingerprint.
