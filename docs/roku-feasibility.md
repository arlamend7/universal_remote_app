# Roku integration feasibility

Roku's [ECP developer reference](https://developer.roku.com/dev/docs/external-control-api)
explicitly restricts ECP commands from third-party platforms, including mobile
apps. [Roku Support](https://support.roku.com/article/install-the-mobile-app)
describes third-party control and the TV's access settings. A device setting
establishes whether the device accepts commands. The two publications do not
establish a clear authorization for distributing this integration.

The implementation gate is written clarification from Roku covering this app
and its distribution, or a documented alternative that authorizes third-party
clients. Discovery and transport should ship together with an authorized control
route. This avoids presenting discoverable devices the app cannot operate.

## Design pending authorization

- Isolate Roku in a pure Dart provider. Reuse SSDP with the Roku service type
  and use the validated service identifier as the discovery identity. Keep
  the saved profile ID separate from the IP address.
- Treat the device's reported transport endpoint as mutable. Validate it
  against the local discovery sender and the approved transport policy.
  ECP's documented HTTP transport requires an explicit transport decision.
- Distinguish Roku TVs and streaming players from reported device information.
  Map navigation, media, apps, power, volume and inputs independently. Derive
  power and volume on streaming players from reported CEC capabilities when
  the approved API exposes them.
- Reuse the registry, typed actions and app collections. Add local protocol
  fixtures for discovery, commands, refusal and endpoint changes once the
  authorized interface is known. Validate on both a Roku TV and a streaming
  player before claiming hardware support.
