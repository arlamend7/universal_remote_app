# Generic TV session lifecycle

`GenericTvController` (runtime, `package:remote_driver_runtime/integrations.dart`)
is the only television controller. It contains no manufacturer logic.

```text
connect()
  └─ IntegrationPlanner.prepare(device)        stage 1: bootstrap integration + profile,
                                                install from catalog/seed if missing
  └─ engine.open(...)                          authenticate; device-scoped credentials
  └─ identify-software (if mapped)             else the session's own software report
  └─ IntegrationPlanner.refine(...)            stage 2: OS/firmware/model → integration
                                                and profile; a different integration
                                                closes and reopens the session once
  └─ verification probes                       declared order, run concurrently, once each
  └─ CapabilityResolver                        evidence from declarations, facts, probes
  └─ IntegrationPlanner.remember(...)          device assignment, in-use tracking
connected
```

The package is resolved inside `connect()`, so no command can be sent before a
verified integration is loaded. This replaces the legacy late-binding closure,
which the app keeps only until the legacy providers are removed.

## Commands

Every `TVRemoteBase` member runs a runtime operation (`volume-up`, `key-mute`,
`read-content`, …) through `OperationGate`:

- unmapped operation → `unsupported`;
- mapped, but its capability (explicit `gate`, the capability whose selected
  operation set contains it, or a declaring capability) is not usable →
  `unavailable`;
- mapping `constraints` are checked before anything is sent (`ArgumentError`);
- a `RemoteException` whose code is in the capability's `disableOn` withdraws the
  capability (`unavailable`, `capabilityChanges` emitted), unless the mapping
  is `readOnly`.

`inputs()`/`applications()` return empty lists when unmapped (the TV offers its
own picker); `playbackState()` returns null when unmapped. `toggleMute` uses a
`toggle-mute` mapping when present, else reads volume and sets the opposite
state. Content readings update `currentInput` when the engine reports inputs.

## Session behaviour

- Pairing: engines that show a code register a submitter; `submitPairingCode`
  forwards to it.
- Facts and unusable engine kinds (for example a closed pointer socket)
  re-resolve capabilities and emit `capabilityChanges`.
- `connection.json#session.reconnectAttempts` controls automatic reconnection
  after an unexpected loss (1 s, 2 s, 4 s back-off). `disconnect()` stops it.
- `connection.json#session.category` sets the device category from a fact.
- Wake: `network.wake-on-lan` uses the learned/configured MAC; engine wake
  mappings run through the session and their capability gate.
- `release()` lets the installer activate a staged update once no session
  uses the integration.

`ManagedIntegrationPlanner` (manager) implements the planner over the
content-addressed installer. It uses installed packages and the cached catalog
offline, and fetches the signed catalog only when no local integration matches
the device's provider. Compiled definitions are cached by package hash.
