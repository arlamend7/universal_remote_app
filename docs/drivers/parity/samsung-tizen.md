# Samsung Tizen parity matrix

Phase 0 baseline for migrating `SamsungController` to the generic declarative driver runtime. Every row below is the acceptance contract for the migrated driver. Source: `packages/remote_driver_runtime/lib/src/adapters/samsung_tizen/**` and `lib/src/samsung/**`. Cross-provider summary: [TV API matrix](tv-api.md), [capability audit](../../provider-capability-audit.md). Wire-level goldens for these rows (`packages/remote_driver_runtime/test/parity/samsung_tizen_parity_test.dart`) are described in the [parity README](README.md).

## Header

| Item | Current behavior |
| --- | --- |
| Provider id | `samsung.tizen` (`ProviderIdentity.samsungTizen.storageId`); managed package id `samsung-tizen`, current source release `drivers/providers/samsung-tizen/1.1.0` (operations `compiled.bindings`, `samsung.session`). Target integration folder `drivers/providers/samsung-tizen/tizen-supported/`. |
| Protocol | Samsung remote channel JSON over WebSocket. Outgoing `{"method":<m>,"params":{…}}`. Incoming events handled: `ms.channel.connect` (approval, `data.token`), `ms.channel.unauthorized` (denial), `ed.installedApp.get` (`data.data` rows). Non-JSON frames and other events ignored. |
| Transport / ports | `wss://<host>:8002/api/v2/channels/samsung.remote.control?name=<base64("Universal Remote")>[&token=<token>]`. Host must be a local probe address. No unencrypted fallback (manual setup rejects legacy). |
| Pairing / credential | TV approval prompt; state `pairing` only when no token is saved. Approval wait 35 s. Token from `ms.channel.connect` `data.token` (string or int) must match `^[a-zA-Z0-9_-]{1,128}$`. Credential JSON `{"pin":<trustedCertificateDer>,"token":<token>}` stored through `CredentialStore.write(device.id, …)` → secure-storage key `client-key.v2.<deviceId>`; written only when a new token differs. A saved token is used only if its `pin` equals the current pin. A denial while using a saved token deletes the credential. |
| Certificate pinning | Metadata `trustedCertificateDer` is mandatory before any connection (`tls` error otherwise, which triggers certificate review). The pin is passed to `IoWebSocketTransport` (empty trust store, exact DER for host:port). Unicast probe compares the presented DER with the pin (450 ms). |
| Device-id formats | Discovery: `samsung.tizen:<usn-uuid lower-case>` (USN must match `^uuid:[0-9a-f-]{16,64}$`). Manual: `newProfileId()` with `stableIdentity:false`; editing keeps the id. |
| Reconnection | None. When the channel closes while connected the controller calls `disconnect()`. Next `connect` reuses the saved token for the same pin. |
| Wake | Wake-on-LAN (UDP broadcast port 9) for metadata `macAddress` (manual or learned by neighbor lookup) to metadata `broadcastAddress` ?? `255.255.255.255`. |
| Software identification | None. Discovery copies SSDP `modelname` into `RemoteDevice.model` only. `sessionSoftwareInformation` is `null`; manufacturer, OS (Tizen) version, firmware, build and protocol version all unknown. No compatibility profile is applied (`bindings.describe(device, null)`). |
| Release restriction | None beyond the managed package staying outside the publishing index until parity is proven. |

Notation: paths in "New driver definition" are relative to `drivers/providers/samsung-tizen/tizen-supported/`. **key(K)**: `{"method":"ms.remote.control","params":{"Cmd":"Click","DataOfCmd":"K","Option":"false","TypeOfRemote":"SendRemoteKey"}}`; completes when the transport write completes (no TV acknowledgment). Not connected → `network` ("Connect to the Samsung TV first."); write failure or closed session → `network`. No Samsung failure disables a capability. `DriverBindings.select` only accepts the compiled fallback, so bindings cannot change a key. Tests are in `packages/remote_driver_runtime/test/adapters/samsung_tizen/samsung_provider_test.dart`.

## Operation matrix

| Original controller method | Protocol behavior (exact wire message: SSAP URI + payload, Android KeyEvent code / Remote v2 message, Samsung KEY_* / launch message, Roku ECP path) | Parameters & validation | Return model | Authentication | Stream behavior | Error handling (codes thrown, capability disabled on failure?) | New driver definition | New runtime operation | Test coverage | Parity status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `connect` | Open WSS URL (header); wait for `ms.channel.connect` / `ms.channel.unauthorized`; then `{"method":"ms.channel.emit","params":{"event":"ed.installedApp.get","to":"host","data":""}}` and wait ≤ 2 s for the catalog | Pin required (`tls`); single endpoint; only from `disconnected`; superseded attempt → `cancelled` | `void`; states connecting → (pairing) → connected | Token from credential when pin matches; new token stored | `connectionStates` broadcast (deduplicated) | `tls` (no pin or handshake), `timeout` (transport or 35 s approval), `network`, `pairingDenied` (+ delete saved token), `cancelled`; failure → `disconnect()` | `workflows/pair.json`, `manifest.json#operations` | `pair` (+ `list-applications`) | `samsung_provider_test.dart` (pairs, sends commands, handles loss and reconnects with its token; requires certificate approval and never reuses a token after pin changes; a rejected stored token is cleared) | pending |
| Session loss (internal) | Transport `onDone`/`onError` → session closed | — | — | — | State `disconnected` | — | `manifest.json` (session policy) | — (no reconnect) | `samsung_provider_test.dart` (handles loss and reconnects) | pending |
| `disconnect` | Close session and transport; pending approval fails `network` | — | `void`; state disconnected | — | Clears cached apps | none | `workflows/pair.json` (close) | — (session close) | `samsung_provider_test.dart` (disconnect cancels pending TV approval) | pending |
| `dispose` | `disconnect()` then close state stream; idempotent | — | `void` | — | Stream closed | none | — | — (session close) | none | pending |
| `evidence` / `supports` | No wire; fixed list while connected (evidence table) | — | `List<CapabilityEvidence>` | — | `capabilityChanges` never emits (default empty stream) | — | `capabilities.json` | — (capabilities.json evaluation) | `samsung_provider_test.dart` (applications and tvSettings supported) | pending |
| `readWakeAddress` | Not implemented | — | — | — | — | — | not defined | none in vocabulary | none | pending |
| `submitPairingCode` | Not implemented; approval on the TV | — | — | — | — | — | not defined | `pair` (no code step) | none | unsupported (preserve) |
| `powerOff` | key(`KEY_POWER`) | — | `void` | Token + pin | — | key errors | `mappings.json#power-off` | `power-off` | `samsung_provider_test.dart` | pending |
| `wake` | Provider `wakeDevice`: WoL magic packet | No MAC → `wakeUnavailable` | `void` | none | — | `wakeUnavailable`, `ArgumentError`, `SocketException` | `mappings.json#wake` + provider wake policy | `wake` | none | pending |
| `canWake` | No wire; `provider.canWakeDevice(device)` evaluated once at controller creation | MAC must normalize | `bool` | — | — | — | `capabilities.json#wake` | `wake` (availability) | none | pending |
| `volumeUp` | key(`KEY_VOLUP`) | — | `void` | Token + pin | — | key errors | `mappings.json#volume-up` | `volume-up` | `samsung_provider_test.dart` (binding to `KEY_POWER` ignored) | pending |
| `volumeDown` | key(`KEY_VOLDOWN`) | — | `void` | Token + pin | — | key errors | `mappings.json#volume-down` | `volume-down` | none | pending |
| `setVolume` | None | — | — | — | — | `unsupported` | not defined | `set-volume` (must stay absent) | none | unsupported (preserve) |
| `setMuted` | None | — | — | — | — | `unsupported` | not defined | `set-mute` (must stay absent) | none | unsupported (preserve) |
| `toggleMute` | `sendKey(mute)` → key(`KEY_MUTE`); resulting state unknown | — | `void` | Token + pin | — | key errors | `mappings.json#toggle-mute` | `toggle-mute` | `samsung_provider_test.dart` (`KEY_MUTE` via sendKey) | pending |
| `readVolume` | None | — | — | — | — | `unsupported` | not defined | `read-volume` (must stay absent) | none | unsupported (preserve) |
| `watchVolume` | None | — | empty stream | — | Never emits | none | not defined | `read-volume` (absent; no `volume` subscription) | none | pending |
| `press(up)` | key(`KEY_UP`) | — | `void` | Token + pin | — | key errors | `mappings.json#navigation-up` | `navigation-up` | none | pending |
| `press(down)` | key(`KEY_DOWN`) | — | `void` | Token + pin | — | key errors | `mappings.json#navigation-down` | `navigation-down` | none | pending |
| `press(left)` | key(`KEY_LEFT`) | — | `void` | Token + pin | — | key errors | `mappings.json#navigation-left` | `navigation-left` | none | pending |
| `press(right)` | key(`KEY_RIGHT`) | — | `void` | Token + pin | — | key errors | `mappings.json#navigation-right` | `navigation-right` | none | pending |
| `press(enter)` | key(`KEY_ENTER`) | — | `void` | Token + pin | — | key errors | `mappings.json#navigation-enter` | `navigation-enter` | `samsung_provider_test.dart` | pending |
| `press(back)` | key(`KEY_RETURN`) | — | `void` | Token + pin | — | key errors | `mappings.json#navigation-back` | `navigation-back` | none | pending |
| `press(home)` | key(`KEY_HOME`) | — | `void` | Token + pin | — | key errors | `mappings.json#navigation-home` | `navigation-home` | none | pending |
| `channelUp` | key(`KEY_CHUP`) | — | `void` | Token + pin | — | key errors | `mappings.json#channel-up` | `channel-up` | none | pending |
| `channelDown` | key(`KEY_CHDOWN`) | — | `void` | Token + pin | — | key errors | `mappings.json#channel-down` | `channel-down` | none | pending |
| `channels` | None | — | — | — | — | `unsupported` | not defined | `list-channels` (must stay absent) | none | unsupported (preserve) |
| `selectChannel` | None | — | — | — | — | `unsupported` | not defined | `select-channel` (must stay absent) | none | unsupported (preserve) |
| `sendMedia(play)` | key(`KEY_PLAY`) (no binding lookup) | — | `void` | Token + pin | — | key errors | `mappings.json#media-play` | `media-play` | none | pending |
| `sendMedia(pause)` | key(`KEY_PAUSE`) | — | `void` | Token + pin | — | key errors | `mappings.json#media-pause` | `media-pause` | none | pending |
| `sendMedia(stop)` | key(`KEY_STOP`) | — | `void` | Token + pin | — | key errors | `mappings.json#media-stop` | `media-stop` | none | pending |
| `sendMedia(rewind)` | key(`KEY_REWIND`) | — | `void` | Token + pin | — | key errors | `mappings.json#media-rewind` | `media-rewind` | none | pending |
| `sendMedia(fastForward)` | key(`KEY_FF`) | — | `void` | Token + pin | — | key errors | `mappings.json#media-fast-forward` | `media-fast-forward` | none | pending |
| `sendMedia(previous)` | None | — | — | — | — | `unsupported` | not defined | `media-previous` (must stay absent) | none | unsupported (preserve) |
| `sendMedia(next)` | None | — | — | — | — | `unsupported` | not defined | `media-next` (must stay absent) | none | unsupported (preserve) |
| `togglePlayback` | None (default) | — | — | — | — | `unsupported` | not defined | `toggle-playback` (must stay absent) | none | unsupported (preserve) |
| `playbackState` | None (default) | — | `null` | — | — | none; generic runtime must return `null`, not throw | not defined | `read-playback` (absent; return null) | none | pending |
| `turnOffScreen` | None (default) | — | — | — | — | `unsupported` | not defined | `screen-off` (must stay absent) | none | unsupported (preserve) |
| `turnOnScreen` | None (default) | — | — | — | — | `unsupported` | not defined | `screen-on` (must stay absent) | none | unsupported (preserve) |
| `movePointer` | None | — | — | — | — | `unsupported` | not defined | `pointer-move` (must stay absent) | none | unsupported (preserve) |
| `scroll` | None | — | — | — | — | `unsupported` | not defined | `pointer-scroll` (must stay absent) | none | unsupported (preserve) |
| `click` | None | — | — | — | — | `unsupported` | not defined | `pointer-click` (must stay absent) | none | unsupported (preserve) |
| `sendKey(digit0…digit9)` | key(`KEY_0`…`KEY_9`) | — | `void` | Token + pin | — | key errors | `mappings.json#key-digit0` … `#key-digit9` | `key-digit0` … `key-digit9` | `samsung_provider_test.dart` (`KEY_3`) | pending |
| `sendKey(enter)` | key(`KEY_ENTER`) | — | `void` | Token + pin | — | key errors | `mappings.json#key-enter` | `key-enter` | none | pending |
| `sendKey(menu, settings)` | Both key(`KEY_MENU`) | — | `void` | Token + pin | — | key errors | `mappings.json#key-menu`, `#key-settings` | `key-menu`, `key-settings` | `samsung_provider_test.dart` (settings → `KEY_MENU`) | pending |
| `sendKey(info, guide, exit)` | key(`KEY_INFO`), key(`KEY_GUIDE`), key(`KEY_EXIT`) | — | `void` | Token + pin | — | key errors | `mappings.json#key-info`, `#key-guide`, `#key-exit` | `key-info`, `key-guide`, `key-exit` | none | pending |
| `sendKey(red, green, yellow, blue)` | key(`KEY_RED`), key(`KEY_GREEN`), key(`KEY_YELLOW`), key(`KEY_BLUE`) | — | `void` | Token + pin | — | key errors | `mappings.json#key-red` … `#key-blue` | `key-red`, `key-green`, `key-yellow`, `key-blue` | none | pending |
| `sendKey(source)` | key(`KEY_SOURCE`) | — | `void` | Token + pin | — | key errors | `mappings.json#key-source` | `key-source` | `samsung_provider_test.dart` | pending |
| `sendKey(mute)` | key(`KEY_MUTE`) | — | `void` | Token + pin | — | key errors | `mappings.json#key-mute` | `key-mute` | `samsung_provider_test.dart` | pending |
| `sendKey(dash, replay, liveTv, captions)` | None | — | — | — | — | `unsupported` | not defined | `key-dash`, `key-replay`, `key-live-tv`, `key-captions` (must stay absent) | none | unsupported (preserve) |
| `sendText` | None | — | — | — | — | `unsupported` | not defined | `send-text` (must stay absent) | none | unsupported (preserve) |
| `sendEnter` | `press(enter)` → key(`KEY_ENTER`) via binding `navigation-enter` | — | `void` | Token + pin | — | key errors | `mappings.json#send-enter` | `send-enter` | none | pending |
| `inputs` | None | — | `[]` always | — | — | none; generic runtime must return `[]`, not throw | `capabilities.json#inputs` (picker only) | `list-inputs` (absent; return empty) | none | pending |
| `selectInput` | None | — | — | — | — | `unsupported` | not defined | `select-input` (must stay absent) | none | unsupported (preserve) |
| `openInputPicker` | `sendKey(source)` → key(`KEY_SOURCE`) | — | `void` | Token + pin | — | key errors | `mappings.json#open-input-picker` | `open-input-picker` | `samsung_provider_test.dart` (`KEY_SOURCE` via sendKey) | pending |
| `currentInput` | None (default) | — | `null` | — | — | none | not defined | `read-input` (absent) | none | pending |
| `currentInputChanges` | None (default) | — | empty stream | — | Never emits | none | not defined | `read-input` (absent; no `input` subscription) | none | pending |
| `applications` | No wire; catalog cached at connect from `ed.installedApp.get` rows `{appId,name}` (≤ 512 rows, id `^[a-zA-Z0-9._-]{1,128}$`, trimmed name 1–200 chars, last duplicate wins) | — | `List<DeviceApplication(id, name)>`; `[]` when the TV did not answer within 2 s | Token + pin | — | none | `mappings.json#list-applications` | `list-applications` | `samsung_provider_test.dart` (invalid row dropped; empty catalog) | pending |
| `launchApplication` | `{"method":"ms.channel.emit","params":{"event":"ed.apps.launch","to":"host","data":{"appId":<id>,"action_type":"DEEP_LINK"}}}` | id `^[a-zA-Z0-9._-]{1,128}$` else `appId`; not checked against the catalog | `void` once the write completes; no launch confirmation | Token + pin | — | `appId`, `network` (write rejected) | `mappings.json#launch-application` | `launch-application` | `samsung_provider_test.dart` (write rejection → `network`; invalid id) | pending |
| `currentApplication` | None | — | — | — | — | `unsupported` | not defined | `read-application` (must stay absent) | none | unsupported (preserve) |
| `reportedApplicationIds` | No wire; ids of the cached catalog | `null` when the catalog is empty | `Set<String>?` | — | — | none | `mappings.json#list-applications` (cached ids) | `list-applications` | none | pending |
| `currentContent` | None | — | — | — | — | `unsupported` | not defined | `read-content` (must stay absent) | none | unsupported (preserve) |
| `watchCurrentContent` | None | — | empty stream | — | Never emits | none | not defined | `read-content` (absent; no `content` subscription) | none | pending |
| `bluetoothAccessories` | None (default) | — | — | — | — | `unsupported` | not defined | `list-accessories` (must stay absent) | none | unsupported (preserve) |
| `toggleBluetoothAccessory` | None (default) | — | — | — | — | `unsupported` | not defined | `toggle-accessory` (must stay absent) | none | unsupported (preserve) |
| `openAccessorySettings` | None (default) | — | — | — | — | `unsupported` | not defined | `open-accessory-settings` (must stay absent) | none | unsupported (preserve) |
| `startVoiceControl` | None (default) | — | — | — | — | `unsupported` | not defined | none (must stay absent) | none | unsupported (preserve) |
| `toggleGameMode` | None (default) | — | — | — | — | `unsupported` | not defined | none (must stay absent) | none | unsupported (preserve) |
| `syncWatchCompanion` | None (default) | — | — | — | — | `unsupported` | not defined | none (must stay absent) | none | unsupported (preserve) |
| `sessionSoftwareInformation` / identity getters | None | `sessionSoftwareInformation`, `verifiedPeerIdentity`, `reportedDiscoveryIdentity` all `null` | `null` | — | — | none | `workflows/identify-software.json` (empty) | `identify-software` (no device query; must not invent versions) | none | pending |

## Capability evidence

| Capability | Availability | Condition / probe |
| --- | --- | --- |
| `navigation`, `numericKeys`, `specialKeys`, `tvSettings`, `inputs`, `mute`, `applications`, `volume`, `channels`, `media`, `power` | known | Unconditional while `state == connected` (after approval and the catalog request). No probe; `applications` stays known with an empty catalog. Never downgraded on failure. |
| `trackNavigation`, `playbackScan`, `playbackToggle`, `absoluteVolume`, `volumeFeedback`, `channelSelection`, `channelCatalog`, `pointer`, `textInput`, `currentContent`, `currentInput`, `screenPower`, `liveTvKey`, `captionsKey`, `instantReplay`, `wake`, `bluetoothAccessories`, `accessorySettings`, `voice`, `gameMode`, `watch` | not reported | Rewind/fast forward keys are sent under `media`; generic `DriverTvCapabilities` places them under `playbackScan`. |

## Provider policies

| Policy | Current behavior |
| --- | --- |
| Manual setup | Label `Samsung Tizen`; advanced setup shown. Endpoint from `samsungEndpoint(address)`: local probe address only (`FormatException` otherwise). `legacy` or `allowInsecurePointer` → `FormatException`. Empty name → `Samsung TV`. Certificate: optional base64 DER, 1–16384 bytes, stored re-encoded (`FormatException` otherwise). MAC optional, must normalize. Broadcast optional IPv4. Existing metadata `trustedCertificateDer`, `macAddress`, `broadcastAddress` are replaced; `macAddressSource` removed when the MAC changes. New id `newProfileId()`, manufacturer `Samsung`. |
| Network configuration view | address, certificate, MAC, broadcast. |
| Controller creation | Single endpoint equal to `samsungEndpoint(host)` with a local host, else `setup`. |
| Certificate review | `canReviewCertificate`: error code `tls` and endpoint scheme `wss`. `trustCertificate` stores the re-encoded DER as `trustedCertificateDer`. |
| sameConnection | Equal `trustedCertificateDer` (plus registry id/provider/endpoint equality). |
| Retry after wake | Codes `network`, `timeout`. |
| mergeDiscovered | Saved device with the discovered endpoints (name, id and metadata kept). |
| Discovery | SSDP ST and service type `urn:samsung.com:service:MultiScreenService:1` (both must match), local host, USN `uuid:` 16–64 hex/dash chars; name `friendlyname` or `Samsung TV`; model `modelname`. Address recognition by unicast SSDP probe. Saved-device probe requires a pin and the canonical endpoint. Tested by `samsung_provider_test.dart` (identifies Samsung SSDP evidence and rejects a public endpoint). |
| Wake provider | `canWakeDevice`: metadata `macAddress` normalizes (provider id is not checked). `wakeDevice`: WoL; otherwise `wakeUnavailable`. |

## Hardware verification

All rows are fixture-verified only (in-memory transport). Check on real Samsung Tizen TVs across model years:

- Certificate presented on 8002 and its stability; approval prompt, token issuance format (string or integer), and token reuse after reboot.
- `ms.channel.unauthorized` on denial and after removing the device in TV settings.
- `ed.installedApp.get` availability and timing (2 s window); `ed.apps.launch` with `DEEP_LINK` for native and web apps.
- Every `KEY_*` above, especially `KEY_POWER` (standby versus off), `KEY_SOURCE`, `KEY_MENU` for settings, `KEY_GUIDE`, colour and media keys in third-party apps.
- Wake-on-LAN from standby with "Power on with mobile" or network standby enabled; retry after wake.
