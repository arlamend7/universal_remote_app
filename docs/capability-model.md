# Capability model

A discovery match establishes protocol compatibility. Capability evidence is
owned by the selected controller and is never used to route an individual
command to another provider.

Device categories include television, air conditioner, media player, speaker,
light, fan, projector, and unknown. Categories do not imply command support.

`CapabilityEvidence` records a capability, its source (advertisement, standardized
discovery, driver, profile, learned command, or user), availability (advertised,
known, verified, unavailable, unsupported), and an optional safe reason.

LG probes volume, application listing, input listing, and pointer-socket setup
without sending destructive controls. Only successful probes expose those typed
controllers. A successful query verifies that operation at that time, not every
command in the interface on every firmware. Later unsupported/permission failures
remove the affected controller; the UI disables it and settings exposes evidence.
Power-off cannot be safely probed, so it is marked driver-known, not verified.
The UI asks before sending it. Wake requires an explicitly configured valid MAC;
a sent magic packet is not proof that the TV woke.

Use a controller without depending on LG command names:

```dart
final controller = registry.createController(device);
await controller.connect();
if (controller is TVRemoteBase && controller.supports(RemoteCapability.volume)) {
  await controller.volumeUp();
}
await controller.dispose();
```

Climate, lighting, channel, and general pointer capability identifiers leave
room for future drivers. Speculative manufacturer APIs have not been created.
The media-playback contract is defined but not advertised by the LG MVP.
