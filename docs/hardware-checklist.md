# Manual LG hardware checklist

Record TV model, firmware, network type, mobile OS/version, and app build.
Do not mark a device supported solely from local fake-server tests.

- Launch on Android 24+ and iOS 15+ physical devices; grant local-network access.
- Verify iOS multicast entitlement/provisioning; Android discovery and lock release.
- Find the TV via SSDP, refresh repeatedly, and verify duplicate advertisements
  collapse while distinct TV UUIDs remain separate.
- Block multicast or use guest Wi-Fi; verify manual IP setup behaves independently.
- Verify unknown TLS certificates are rejected. Provision an independently verified
  exact pin, connect, then verify an incorrect/changed pin is rejected.
- Verify no silent downgrade. Test explicit legacy transport only on a trusted LAN.
- Approve pairing on the TV; reject once, cancel once, and allow a prompt to time out.
- Relaunch the app/device and confirm saved-key reuse without exposing the key.
- Revoke authorization on the TV, retry, verify the stale key is removed, then re-pair.
- Check volume up/down, set 0/100, mute/unmute, read/subscribed state and external
  sound-output variations. Confirm unsupported controls disable with useful errors.
- Check every directional button, OK, Back, Home and pointer-socket loss. Verify
  explicit consent is required if the pointer uses unencrypted transport.
- List applications and launch by returned IDs. List inputs and switch by returned
  IDs. Test empty lists and permission-denied responses.
- Confirm power-off with the user. Enable TV network wake and connect while it
  is on. Confirm the learned MAC/broadcast match the active network interface,
  or configure them manually. Test WOL across supported sleep/network states.
  Confirm that the app reconnects automatically and the remote controls work
  after startup. Record unsupported situations.
- Rename, edit network address, change theme, restart, and verify persistence.
- Forget a TV and confirm its protected client key is deleted; reconnect requires
  authorization. Test native-storage failures without plaintext fallback.
- Disable Wi-Fi, turn TV off, drop sockets, then restore network. Check bounded
  reconnection, foreground resumption, cancellation, and no duplicate commands.
- Background the app during discovery and pairing; inspect resource release.
- Enable diagnostics and inspect native/debug logs for accidental secrets.

All physical-TV and physical-mobile-device items remain unverified.
