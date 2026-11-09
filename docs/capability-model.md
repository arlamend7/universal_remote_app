# Capability model

A discovery match establishes protocol compatibility. Capability evidence is
owned by the selected controller and is never used to route an individual
command to another provider.

Device categories include television, air conditioner, media player, speaker,
light, fan, projector, and unknown. Categories do not imply command support.

`CapabilityEvidence` records a capability, its source (advertisement, standardized
discovery, driver, profile, learned command, or user), availability (advertised,
known, verified, unavailable, unsupported), and an optional safe reason.

A valid volume read verifies feedback only. Relative volume, absolute volume
and mute have separate evidence. A provider can revoke one after a firmware
rejection without affecting the others. A pointer-channel setup establishes
a usable path for driver-known controls. App and input catalogs must contain
usable entries before the corresponding chooser is enabled. A socket write
does not verify a command or an app launch.

Providers publish session capability changes separately from connection
states. The app evaluates the active driver and does not enable controls based
on a saved capability snapshot. Power-off stays driver-known because sending
it as a probe would change the TV state.

See the [provider capability audit](provider-capability-audit.md) for command
mappings, test coverage, limitations and physical verification status.

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
Playback toggle and discrete media keys have separate capability requirements.
