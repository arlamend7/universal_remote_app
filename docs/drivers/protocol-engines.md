# Protocol engines

Engines are the only compiled, executable part of an integration. They live
in `packages/remote_driver_runtime/lib/src/engines/` and are exported by
`package:remote_driver_runtime/protocol_engines.dart`.

An engine:

- owns one protocol: transport, authentication, pairing, framing, decoders
  and composite protocol procedures;
- exposes a closed set of **operation kinds** and validates every mapping's
  parameters (`compile`) before an integration can be activated;
- validates its `connection.json` section (`compileConnection`);
- opens an `EngineSession` that executes compiled operations, streams
  subscriptions and reports session **facts** (negotiated features,
  device-info flags, reported apps), identified software, and operation
  kinds that became unusable.

Engines never choose a provider, integration or compatibility profile, and
JSON can never introduce code, URLs outside the engine's allow-list or
unbounded messages.

| Engine ID | Protocol | Kinds | Validation highlights |
|---|---|---|---|
| `ssap` | SSAP over WebSocket (TLS default; `ws` only when the integration allows legacy transport **and** the user opted in), prompt pairing, pointer socket | `ssap.request`, `ssap.subscribe`, `ssap.pointer-open/-button/-move/-scroll/-click`, `ssap.read-content`, `ssap.launch`, `ssap.launch-reported`, `ssap.toggle-accessory`, `ssap.identify`, `ssap.wake-address` | URIs restricted to known service namespaces; payloads are ≤4 KB templates whose leaves reference only named call arguments; closed decoder set; registration manifest limited to `manifestVersion`, `appVersion`, upper-case permissions |
| `android-remote-v2` | Android TV Remote v2: certificate pairing, pinned TLS, varint-framed protobuf | `remote-v2.key`, `.wake`, `.text`, `.submit`, `.app-link`, `.set-volume`, `.set-mute`, `.read-volume`, `.read-content`, `.volume`, `.content` | `KeyEvent` codes 0–319 only; app links through the existing safe link parser |
| `samsung-channel` | Samsung secure remote channel: pinned WebSocket, on-screen authorization, issued token | `samsung-channel.key`, `.launch`, `.applications` | `KEY_[A-Z0-9_]{1,32}` keys; app IDs `[a-zA-Z0-9._-]{1,128}`; certificate must be reviewed first |
| `roku-ecp` | Roku ECP over local HTTP | `roku-ecp.key`, `.text`, `.launch`, `.applications`, `.inputs`, `.select-input`, `.channels`, `.read-content`, `.playback` | Documented ECP key names only; input keys declared per integration must be `Input*` keys; launch only for reported apps |
| `json-websocket` | Generic JSON request/reply over TLS WebSocket with code pairing and token auth | `json-websocket.request`, `.subscribe` | Bounded message templates; reserved envelope fields (`id`, `code`, `token`) belong to the engine |

The runtime itself executes `network.wake-on-lan`.

`ProtocolEngineRegistry` reports a missing engine (`missingEngine`) or the
exact missing operation kinds/runtime API level for an integration rather than
silently ignoring them.

During the migration the legacy manufacturer controllers share the moved
protocol helpers (pointer socket, transport error mapping, SSAP software
parsing, wake-address reader, ECP parsers); the wire-level parity goldens
confirm their behaviour is unchanged.
