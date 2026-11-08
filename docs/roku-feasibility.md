# Roku integration feasibility

Roku's [ECP developer reference](https://developer.roku.com/dev/docs/external-control-api)
explicitly restricts ECP commands from third-party platforms, including mobile
apps. [Roku Support](https://support.roku.com/article/install-the-mobile-app)
describes third-party control and the TV's access settings. A device setting
establishes whether the device accepts commands. The two publications do not
establish a clear authorization for distributing this integration.

## Local development integration

The pure Dart Roku provider is disabled by default and excluded from provider
registration in release builds. The development flag is for testing on a local
network where this use is authorized. It is not confirmation that distribution
is authorized. Written clarification or a documented authorized alternative is
still required before enabling it in distributed builds.

From `apps/universal_remote_app`, run:

```sh
flutter run --dart-define=ENABLE_ROKU_ECP=true
```

Use **Find Nearby Devices** or **Connect by IP → Roku (local HTTP)**. If the TV
denies key commands, check **Settings → System → Advanced system settings →
Control by mobile apps** and use **Enabled** for same-network control.

- SSDP discovery checks the Roku service type, serial and advertised location.
  It uses the response sender's private IPv4 address and keeps the serial
  separate from the mutable IP address.
- ECP uses local HTTP directly, with bounded timeouts and response sizes.
  Redirects and proxies are disabled. The provider never downgrades a secure
  connection.
- The provider offers navigation, a Play/Pause key and text entry. App
  shortcuts, current activity, inputs, volume buttons and power off depend on
  the device information or successful read queries. A denied command removes
  its capability for the current session. Absolute volume and explicit mute
  are not advertised.
- The existing dashboard renders the controls. Protocol tests use a local
  HTTP server. Physical Roku TV and streaming-player validation is pending.

The workspace pins `xml` 6.6.1 for ECP responses and records the resolved
parser dependency in the audit snapshot.
