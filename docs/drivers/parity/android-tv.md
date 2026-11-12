# Android TV / Google TV parity matrix

> **Historical baseline.** The `adapters/android_tv/**` sources, `ProviderIdentity`, `DriverBindings` and `workflows/*.json` referenced below were removed by the migration. The protocol now lives in `packages/remote_driver_runtime/lib/src/remote_v2/**` and `lib/src/engines/remote_v2/**`, and the integration in `drivers/providers/android-tv/remote-v2/`. Manufacturer-specific notes (TCL) are in [tcl-google-tv-integration.md](../tcl-google-tv-integration.md).

Phase 0 baseline for migrating `AndroidTvController` to the generic declarative driver runtime. Every row below is the acceptance contract for the migrated driver. Source: `packages/remote_driver_runtime/lib/src/adapters/android_tv/**` and `lib/src/remote_v2/**`. Cross-provider summary: [TV API matrix](tv-api.md), [capability audit](../../provider-capability-audit.md). Wire-level goldens for these rows (`packages/remote_driver_runtime/test/parity/android_tv_parity_test.dart`) are described in the [parity README](README.md).

## Header

| Item | Current behavior |
| --- | --- |
| Provider id | `android.tv` (`ProviderIdentity.androidTv.storageId`); managed package id `android-tv`, current source release `drivers/providers/android-tv/1.1.0` (operations `compiled.bindings`, `remote-v2.session`). Target integration folder `drivers/providers/android-tv/remote-v2/`. |
| Protocol | Android TV Remote v2: protobuf-style messages (varint and length-delimited fields only) framed by a varint length prefix, max frame 256 KiB, empty frame rejected. Notation below: `{f:{…}}` = outer field `f` carrying an encoded sub-message. |
| Transport / ports | Pairing TLS on `6467`, remote TLS on `6466` (`tls://<host>:6466` endpoint). TLS ≥ 1.2, `SecurityContext(withTrustedRoots:false)` with the client certificate. Connect timeout 8 s; remote session must reach "ready" within 10 s; idle read timeout 140 s closes the session. |
| Pairing / credential | First connect without a credential: generate RSA-2048 self-signed client certificate (CN `Universal Remote <serial>`, SHA-256, 10-year validity). Pairing envelopes `{1:2, 2:200, <field>:…}`: `10 {1:"atvremote",2:"Universal Remote"}` → expects 11; `20 {1:{1:3,2:6},3:1}` → 20; `30 {1:{1:3,2:6},2:1}` → 31; state `pairing`; code entry (2 min); `40 {1:secret}` → 41. Each step waits 10 s. Credential JSON `{"certificate":<PEM>,"key":<PEM>,"peer":<fingerprint>}` stored through `CredentialStore.write(device.id, …)` → secure-storage key `client-key.v2.<deviceId>`. Never deleted automatically. |
| Certificate pinning | Pairing accepts the TV certificate (trust comes from the on-screen code) and records `peer` = base64 SHA-256 of the TV certificate DER. Remote session rejects any peer whose fingerprint differs (`certificate`). `verifiedPeerIdentity` = that fingerprint (the app persists it as metadata `verifiedPeerIdentity`). Discovery stores the unauthenticated 6467 fingerprint as `advertisedPeerIdentity`. `trustedCertificateDer` is not used. |
| Device-id formats | Discovery: `android-tv-<base64 SHA-256 fingerprint>` with `stableIdentity:true` when the 6467 certificate can be read; otherwise `newProfileId()` with `stableIdentity:false` (provisional). Manual: `newProfileId()`, `stableIdentity:false`; editing keeps the id. |
| Reconnection | None. On socket close/error, remote error field 3, or 140 s idle, the session closes and the controller calls `disconnect()` (state `disconnected`). The next `connect` reuses the stored credential. |
| Wake | Wake-on-LAN (UDP broadcast port 9) to metadata `broadcastAddress` ?? `255.255.255.255` for metadata `macAddress`. No manual MAC field; MAC is learned after a connection by the neighbor resolver (`localNeighbor`). The controller is not a `DeviceWakeAddressSource`. |
| Software identification | No device query. After connect: `source=authenticatedSession`, `operatingSystem="Android TV"`, `protocolVersion="Remote v2"`, `identifiedAt`. Unknown: `manufacturer`, `model`, `hardwareModel`, `operatingSystemVersion`, `softwareVersion`, `firmwareVersion`, `buildNumber`, `raw`. `sessionSoftwareInformation` only while connected. No compatibility profile is applied (`bindings.describe(device, null)`). |
| Release restriction | None beyond the managed package staying outside the publishing index until parity is proven. |

Notation: paths in "New driver definition" are relative to `drivers/providers/android-tv/remote-v2/`. **key(c)**: Remote v2 key injection `{10:{1:c,2:3}}` (direction 3 = short press) followed by a socket flush. Not connected → `unsupported`; keys feature not negotiated or session not ready → `remote`; write after close → `network`. No Android failure disables a capability; evidence comes only from negotiated features and audio reports. `DriverBindings.select` only accepts the compiled fallback, so bindings cannot change a key code. Tests are under `packages/remote_driver_runtime/test/adapters/android_tv/`; there is no controller-level `AndroidTvController` test.

## Operation matrix

| Original controller method | Protocol behavior (exact wire message: SSAP URI + payload, Android KeyEvent code / Remote v2 message, Samsung KEY_* / launch message, Roku ECP path) | Parameters & validation | Return model | Authentication | Stream behavior | Error handling (codes thrown, capability disabled on failure?) | New driver definition | New runtime operation | Test coverage | Parity status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `connect` | Pair if no credential (header), then remote TLS 6466 with the client certificate; TV `{1:{1:offered}}` → reply `{1:{1:offered & 615, 2:{3:<2 on iOS, else 1>,5:"Universal Remote",6:"1.0"}}}`; TV `{2:…}` → reply `{2:{1:features}}` and ready; TV ping `{8:{1:n}}` → `{9:{1:n}}` | Single endpoint host required; only from `disconnected`; disposed → no-op; superseded attempt → `cancelled` | `void`; states connecting → (pairing) → connected | Stored credential decoded; TV fingerprint must equal `peer` | `connectionStates` broadcast (deduplicated) | `certificate` (pin mismatch or handshake), `pairing` (non-200 or wrong reply), `cancelled`, `remote` (not ready in 10 s); raw `TimeoutException`/`SocketException` also propagate; failure → `disconnect()` | `workflows/pair.json`, `manifest.json#operations` | `pair` | `android_tv_protocol_test.dart` (pairs using a TV code and reconnects with the pinned certificate; rejects a mismatched certificate) | parity (generic golden) |
| `submitPairingCode` | Secret = SHA-256(client modulus‖exponent ‖ TV modulus‖exponent ‖ 2 nonce bytes from code chars 3–6); first byte must equal code chars 1–2 | 6 hex chars; returns `false` when no pairing is waiting, already submitted, malformed or checksum mismatch | `Future<bool>` | Pairing socket | — | No throw | `workflows/pair.json#code` | `pair` | `android_tv_protocol_test.dart` (invalid code false, valid code true) | parity (generic golden) |
| Session loss (internal) | Socket close/error, `{3:…}` error message, 140 s idle | — | — | — | Session streams close; state `disconnected` | — | `manifest.json` (session policy) | — (no reconnect) | `android_tv_protocol_test.dart` (lost callback after server closes) | parity (generic golden) |
| `disconnect` | Close pending pairing (completes code wait with `cancelled`), cancel audio listener, destroy socket | — | `void`; state disconnected | — | — | none | `workflows/pair.json` (close) | — (session close) | `android_tv_protocol_test.dart` (cancels on-screen pairing without submitting a secret, session level) | parity (generic golden) |
| `dispose` | `disconnect()` then close state and capability streams; idempotent | — | `void` | — | Streams closed | none | — | — (session close) | none | parity (generic golden) |
| `evidence` / `supports` / `capabilityChanges` | No wire; from negotiated features and field 50 reports (evidence table) | Empty unless connected | `List<CapabilityEvidence>` (source `driver`) | — | `capabilityChanges` fires when (volume reported, absolute mode, adjustable mode) changes | — | `capabilities.json` | — (capabilities.json evaluation) | `android_tv_protocol_test.dart` (features 615, absolute volume, session level only) | parity (generic golden) |
| `readWakeAddress` | Not implemented | — | — | — | — | — | not defined | none in vocabulary | none | parity (generic golden) |
| `powerOff` | key(223) | `supports(power)` else `unsupported` | `void` | Paired TLS | — | key errors | `mappings.json#power-off` | `power-off` | none | parity (generic golden) |
| `wake` | Provider `wakeDevice`: WoL magic packet to MAC/broadcast from metadata | No MAC → `wakeUnavailable` | `void` | none | — | `wakeUnavailable`, `ArgumentError`, `SocketException` | `mappings.json#wake` + provider wake policy | `wake` | `android_wake_test.dart` | parity (generic golden) |
| `canWake` | No wire; `provider.canWakeDevice(device)` evaluated once when the controller is created | MAC must normalize | `bool` | — | — | — | `capabilities.json#wake` | `wake` (availability) | `android_wake_test.dart` | parity (generic golden) |
| `volumeUp` | key(24) | `supports(volume)` else `unsupported` | `void` | Paired TLS | — | key errors | `mappings.json#volume-up` | `volume-up` | `android_tv_protocol_test.dart` (24; binding `99999` ignored) | parity (generic golden) |
| `volumeDown` | key(25) | `supports(volume)` else `unsupported` | `void` | Paired TLS | — | key errors | `mappings.json#volume-down` | `volume-down` | none | parity (generic golden) |
| `setVolume` | `{50:{1:outputId,2:min+round((max−min)·v/100),3:<1 if muted else 0>}}` | Session required (`unsupported`); output mode 2 (absolute) and 0–100 else `unsupported` | `void` | Paired TLS | — | `unsupported`, `network` | `mappings.json#set-volume` | `set-volume` | `android_tv_protocol_test.dart` (60 → level 15 of 25) | parity (generic golden) |
| `setMuted` | No wire when reported mute already equals target; else `{51:{1:outputId,2:2}}` | Session required; output mode 1 or 2 else `unsupported` | `void` | Paired TLS | — | `unsupported`, `network` | `mappings.json#set-mute` | `set-mute` | `android_tv_protocol_test.dart` (unmute sends `{1:3,2:2}`) | parity (generic golden) |
| `toggleMute` | `sendKey(mute)` → key(164) | as `sendKey` | `void` | Paired TLS | — | key errors | `mappings.json#toggle-mute` | `toggle-mute` | `android_key_codes_test.dart` (164) | parity (generic golden) |
| `readVolume` | No wire; last TV report `{50:{1:id,4:mode,5:min,6:max,7:level,8:muted}}` (parsed only when feature 64 negotiated) | No report yet → `unsupported` | `VolumeState(round(100·(level−min)/(max−min)), muted)` | Paired TLS | — | `unsupported` | `mappings.json#read-volume` | `read-volume` | `android_tv_protocol_test.dart` (volume 40, muted) | parity (generic golden) |
| `watchVolume` | TV-pushed field 50 reports | Empty stream without a session | `Stream<VolumeState>` | Paired TLS | Broadcast, no replay of the current value; closes with the session | none | `mappings.json#read-volume` + subscription `volume` | `read-volume` (+ subscription `volume`) | `android_tv_protocol_test.dart` (`volumes.first`) | parity (generic golden) |
| `press(up)` | key(19) | No capability check; key errors | `void` | Paired TLS | — | key errors | `mappings.json#navigation-up` | `navigation-up` | none | parity (generic golden) |
| `press(down)` | key(20) | as above | `void` | Paired TLS | — | key errors | `mappings.json#navigation-down` | `navigation-down` | none | parity (generic golden) |
| `press(left)` | key(21) | as above | `void` | Paired TLS | — | key errors | `mappings.json#navigation-left` | `navigation-left` | none | parity (generic golden) |
| `press(right)` | key(22) | as above | `void` | Paired TLS | — | key errors | `mappings.json#navigation-right` | `navigation-right` | none | parity (generic golden) |
| `press(enter)` | key(23) | as above | `void` | Paired TLS | — | key errors | `mappings.json#navigation-enter` | `navigation-enter` | `android_tv_protocol_test.dart` (23) | parity (generic golden) |
| `press(back)` | key(4) | as above | `void` | Paired TLS | — | key errors | `mappings.json#navigation-back` | `navigation-back` | none | parity (generic golden) |
| `press(home)` | key(3) | as above | `void` | Paired TLS | — | key errors | `mappings.json#navigation-home` | `navigation-home` | none | parity (generic golden) |
| `channelUp` | key(166) (no binding lookup) | key errors | `void` | Paired TLS | — | key errors | `mappings.json#channel-up` | `channel-up` | `android_tv_protocol_test.dart` (166) | parity (generic golden) |
| `channelDown` | key(167) (no binding lookup) | key errors | `void` | Paired TLS | — | key errors | `mappings.json#channel-down` | `channel-down` | `android_tv_protocol_test.dart` (167) | parity (generic golden) |
| `channels` | None | — | — | — | — | `unsupported` | not defined | `list-channels` (must stay absent) | none | unsupported (preserve) |
| `selectChannel` | None | — | — | — | — | `unsupported` | not defined | `select-channel` (must stay absent) | none | unsupported (preserve) |
| `sendMedia(play)` | key(126) | key errors | `void` | Paired TLS | — | key errors | `mappings.json#media-play` | `media-play` | `android_key_codes_test.dart` (126) | parity (generic golden) |
| `sendMedia(pause)` | key(127) | key errors | `void` | Paired TLS | — | key errors | `mappings.json#media-pause` | `media-pause` | none | parity (generic golden) |
| `sendMedia(stop)` | key(86) | key errors | `void` | Paired TLS | — | key errors | `mappings.json#media-stop` | `media-stop` | none | parity (generic golden) |
| `sendMedia(rewind)` | key(89) | key errors | `void` | Paired TLS | — | key errors | `mappings.json#media-rewind` | `media-rewind` | none | parity (generic golden) |
| `sendMedia(fastForward)` | key(90); legacy binding key is `media-fastforward` (`action.name.toLowerCase()`) | key errors | `void` | Paired TLS | — | key errors | `mappings.json#media-fast-forward` (rename from 1.1.0 `media-fastforward`) | `media-fast-forward` | none | parity (generic golden) |
| `sendMedia(previous)` | key(88) | key errors | `void` | Paired TLS | — | key errors | `mappings.json#media-previous` | `media-previous` | `android_key_codes_test.dart` (88) | parity (generic golden) |
| `sendMedia(next)` | key(87) | key errors | `void` | Paired TLS | — | key errors | `mappings.json#media-next` | `media-next` | `android_key_codes_test.dart` (87) | parity (generic golden) |
| `togglePlayback` | None (default) | — | — | — | — | `unsupported` | not defined | `toggle-playback` (must stay absent) | none | unsupported (preserve) |
| `playbackState` | None (default) | — | `null` | — | — | none; generic runtime must return `null`, not throw | not defined | `read-playback` (absent; return null) | none | parity (generic golden) |
| `turnOffScreen` | None (default) | — | — | — | — | `unsupported` | not defined | `screen-off` (must stay absent) | none | unsupported (preserve) |
| `turnOnScreen` | None (default) | — | — | — | — | `unsupported` | not defined | `screen-on` (must stay absent) | none | unsupported (preserve) |
| `movePointer` | None | — | — | — | — | `unsupported` | not defined | `pointer-move` (must stay absent) | none | unsupported (preserve) |
| `scroll` | None | — | — | — | — | `unsupported` | not defined | `pointer-scroll` (must stay absent) | none | unsupported (preserve) |
| `click` | None | — | — | — | — | `unsupported` | not defined | `pointer-click` (must stay absent) | none | unsupported (preserve) |
| `sendKey(digit0…digit9)` | key(7 + digit), i.e. 7…16 | key errors | `void` | Paired TLS | — | key errors | `mappings.json#key-digit0` … `#key-digit9` | `key-digit0` … `key-digit9` | `android_key_codes_test.dart` (0 → 7, 9 → 16) | parity (generic golden) |
| `sendKey(enter)` | key(23) | key errors | `void` | Paired TLS | — | key errors | `mappings.json#key-enter` | `key-enter` | none | parity (generic golden) |
| `sendKey(menu)` | key(82) | key errors | `void` | Paired TLS | — | key errors | `mappings.json#key-menu` | `key-menu` | `android_key_codes_test.dart` | parity (generic golden) |
| `sendKey(info, guide)` | key(165), key(172) | key errors | `void` | Paired TLS | — | key errors | `mappings.json#key-info`, `#key-guide` | `key-info`, `key-guide` | `android_key_codes_test.dart` | parity (generic golden) |
| `sendKey(exit)` | key(4) (same code as Back) | key errors | `void` | Paired TLS | — | key errors | `mappings.json#key-exit` | `key-exit` | `android_key_codes_test.dart` | parity (generic golden) |
| `sendKey(red, green, yellow, blue)` | key(183), key(184), key(185), key(186) | key errors | `void` | Paired TLS | — | key errors | `mappings.json#key-red` … `#key-blue` | `key-red`, `key-green`, `key-yellow`, `key-blue` | `android_key_codes_test.dart` | parity (generic golden) |
| `sendKey(source)` | key(178) | key errors | `void` | Paired TLS | — | key errors | `mappings.json#key-source` | `key-source` | `android_key_codes_test.dart` (178) | parity (generic golden) |
| `sendKey(settings)` | key(176) | key errors | `void` | Paired TLS | — | key errors | `mappings.json#key-settings` | `key-settings` | none | parity (generic golden) |
| `sendKey(mute)` | key(164) | key errors | `void` | Paired TLS | — | key errors | `mappings.json#key-mute` | `key-mute` | `android_key_codes_test.dart` (164) | parity (generic golden) |
| `sendKey(liveTv)` | key(170) | key errors | `void` | Paired TLS | — | key errors | `mappings.json#key-live-tv` | `key-live-tv` | `android_key_codes_test.dart` (170) | parity (generic golden) |
| `sendKey(captions)` | key(175) | key errors | `void` | Paired TLS | — | key errors | `mappings.json#key-captions` | `key-captions` | `android_key_codes_test.dart` (175) | parity (generic golden) |
| `sendKey(dash, replay)` | None (no key code) | — | — | — | — | `unsupported` | not defined | `key-dash`, `key-replay` (must stay absent) | `android_key_codes_test.dart` (replay → null) | unsupported (preserve) |
| `sendText` | IME batch edit `{21:{1:imeId,2:counter,3:{2:{1:start,2:end,3:text}}}}` replacing the reported selection | IME feature (4) and ≤ 512 UTF-16 units else `text`; no focused field → `keyboardFocus`; no session → `unsupported` | `void` | Paired TLS | — | `text`, `keyboardFocus`, `network`, `unsupported` | `mappings.json#send-text` | `send-text` | `android_tv_protocol_test.dart` (`abc`) | parity (generic golden) |
| `sendEnter` | `{21:{1:imeId,2:counter,3:{5:{1:action}}}}`, action from the focus report (`20 → 1 → field 6`) | Action > 0 required else `keyboardFocus` | `void` | Paired TLS | — | `keyboardFocus`, `network`, `unsupported` | `mappings.json#send-enter` | `send-enter` | `android_tv_protocol_test.dart` (submit action 3) | parity (generic golden) |
| `inputs` | None | — | `[]` always | — | — | none; generic runtime must return `[]`, not throw | `capabilities.json#inputs` (picker only) | `list-inputs` (absent; return empty) | none | parity (generic golden) |
| `selectInput` | None | — | — | — | — | `unsupported` | not defined | `select-input` (must stay absent) | none | unsupported (preserve) |
| `openInputPicker` | `sendKey(source)` → key(178) | key errors | `void` | Paired TLS | — | key errors | `mappings.json#open-input-picker` | `open-input-picker` | `android_key_codes_test.dart` (178) | parity (generic golden) |
| `currentInput` | None (default) | — | `null` | — | — | none | not defined | `read-input` (absent) | none | parity (generic golden) |
| `currentInputChanges` | None (default) | — | empty stream | — | Never emits | none | not defined | `read-input` (absent; no `input` subscription) | none | parity (generic golden) |
| `applications` | None | — | `[]` always | — | — | none; generic runtime must return `[]`, not throw | `capabilities.json#applications` (launch only) | `list-applications` (absent; return empty) | none | parity (generic golden) |
| `launchApplication` | App link `{90:{1:<link>}}`; package id → `market://launch?id=<pkg>`; `vnd.youtube://` and credential-free `https://host…` sent unchanged | ≤ 512 chars; package `^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z0-9_]+)+$`; otherwise or without `supports(applications)` → `appLink`; session without app-link feature → `unsupported` | `void` (write + flush only) | Paired TLS | — | `appLink`, `unsupported`, `network` | `mappings.json#launch-application` | `launch-application` | `android_key_codes_test.dart` (market link; unsafe targets refused), `android_tv_protocol_test.dart` (`vnd.youtube://`) | parity (generic golden) |
| `currentApplication` | No wire; last IME focus package | — | `String?` (`null` when none) | Paired TLS | — | none | `mappings.json#read-application` | `read-application` | none | parity (generic golden) |
| `reportedApplicationIds` | None (default) | — | `null` | — | — | none | not defined | `list-applications` (absent) | none | parity (generic golden) |
| `currentContent` | No wire; TV IME focus `{20:{1:{…,12:<package>}}}` with package matching `^[a-zA-Z0-9_.]{1,200}$` | No report → `unsupported` | `CurrentContent(appId: package)` only | Paired TLS | — | `unsupported` | `mappings.json#read-content` | `read-content` | `android_tv_protocol_test.dart` (`com.example.tv`) | parity (generic golden) |
| `watchCurrentContent` | Same focus reports | Empty stream without a session | `Stream<CurrentContent>` | Paired TLS | Broadcast, no replay; closes with the session | none | `mappings.json#read-content` + subscription `content` | `read-content` (+ subscription `content`) | none | parity (generic golden) |
| `bluetoothAccessories` | None (default) | — | — | — | — | `unsupported` | not defined | `list-accessories` (must stay absent) | none | unsupported (preserve) |
| `toggleBluetoothAccessory` | None (default) | — | — | — | — | `unsupported` | not defined | `toggle-accessory` (must stay absent) | none | unsupported (preserve) |
| `openAccessorySettings` | None | — | — | — | — | `unsupported` | not defined | `open-accessory-settings` (must stay absent) | none | unsupported (preserve) |
| `startVoiceControl` | None (default) | — | — | — | — | `unsupported` | not defined | none (must stay absent) | none | unsupported (preserve) |
| `toggleGameMode` | None (default) | — | — | — | — | `unsupported` | not defined | none (must stay absent) | none | unsupported (preserve) |
| `syncWatchCompanion` | None (default) | — | — | — | — | `unsupported` | not defined | none (must stay absent) | none | unsupported (preserve) |
| `sessionSoftwareInformation` / identity getters | No wire | Only while connected; `verifiedPeerIdentity` = TV fingerprint; `reportedDiscoveryIdentity` = `null` | `DeviceSoftwareInformation` (header) | Paired TLS | — | none | `workflows/identify-software.json` | `identify-software` | none | parity (generic golden) |

## Capability evidence

Features offered by the TV are masked to `1 | 2 | 4 | 32 | 64 | 512` (= 615). Evidence is empty unless connected.

| Capability | Availability | Condition / probe |
| --- | --- | --- |
| `navigation`, `media`, `numericKeys`, `tvSettings`, `specialKeys`, `trackNavigation`, `liveTvKey`, `captionsKey`, `inputs`, `mute` | known | `supportsKeys`: feature bit 2 negotiated. |
| `channels` | known | `supportsKeys`; reason "Sends channel keys to the active TV input or app." |
| `volume` | known | `supportsVolumeKeys` (= `supportsKeys`). |
| `textInput`, `currentContent` | known | `supportsIme`: feature bit 4. |
| `applications` | known | `supportsAppLinks`: feature bit 512. |
| `absoluteVolume` | known | `supportsAbsoluteVolume`: latest valid field-50 report has mode 2. Changes emit `capabilityChanges`. |
| `power` | known | `supportsPower`: bit 2 and bit 32. |
| `volumeFeedback` | verified | A valid field-50 report was received (parsed only with bit 64). |
| `setMuted` readiness | not separate evidence | `supportsMute` (mode 1 or 2) is enforced at call time; `mute` evidence comes from the key bit. |
| `playbackScan`, `wake`, `pointer`, `channelSelection`, `channelCatalog`, `currentInput`, `screenPower`, `bluetoothAccessories`, `accessorySettings`, `instantReplay`, `playbackToggle`, `voice`, `gameMode`, `watch` | not reported | Rewind/fast forward keys are sent under `media`; generic `DriverTvCapabilities` places them under `playbackScan`. |

## Provider policies

| Policy | Current behavior |
| --- | --- |
| Manual setup | Label `Google TV / Android TV`; advanced setup hidden. Endpoint `tls://<ip>:6466`. Address must parse as IP, not loopback or multicast (public addresses accepted). `legacy` or `allowInsecurePointer` → `FormatException` ("Android TV requires a secure connection."). Empty name → `Android TV`. New id `newProfileId()`; editing keeps the id and only replaces name and endpoint. |
| Network configuration view | address only. |
| Certificate review | None (no `DeviceConnectionPolicy`); registry returns false. Trust is the paired fingerprint. |
| sameConnection | Registry default: same id, provider and endpoints. |
| Retry after wake | Registry default: false. |
| mergeDiscovered | Registry default: discovered device with saved name and metadata `{...discovered, ...saved}`. |
| Discovery | Bonjour `_androidtvremote2._tcp` on port 6466 only (native adapter on iOS, Dart mDNS elsewhere); name from the Bonjour instance name or `Android TV` (TXT records were not read at baseline); reads the 6467 certificate fingerprint without trusting it (900 ms). Address recognition requires equal fingerprints on 6466 and 6467. Saved-device probe compares `verifiedPeerIdentity` (or `advertisedPeerIdentity`) to the 6466 fingerprint (450 ms). Tested by `android_tv_identifier_test.dart`. |
| Wake provider | `canWakeDevice`: provider matches and metadata `macAddress` normalizes. `wakeDevice`: WoL; otherwise `wakeUnavailable` ("…Connect once so it can be learned."). |

## Hardware verification

All rows are fixture-verified only (loopback TLS servers with generated certificates). Check on real Google TV / Android TV devices (including TCL):

- Pairing flow: code display, checksum byte, 2-minute timeout, and behavior after the TV forgets the client (stored credential is never cleared automatically).
- Feature bits offered by each model; whether bit 32 (power) and bit 64 (volume) appear.
- Every KeyEvent code above, especially 223 (power off), 176 (settings), 178 (input picker), 170 (Live TV), 175 (captions), 166/167 (channel) on non-tuner devices, and colour keys.
- Field 50/51 audio reports and writes on TV speakers, HDMI-CEC and fixed-volume outputs.
- IME focus reports, text replacement and submit action in several apps; foreground package reporting.
- App links (`market://launch?id=`, `vnd.youtube://`, https) per launcher.
- 140 s idle timeout versus TV ping interval; Wake-on-LAN from standby with network wake enabled.

## Migration status

`drivers/providers/android-tv/remote-v2` reproduces every row above through
`GenericTvController`. Each step's recorded wire frames, results, error codes
and capability evidence equal the legacy golden
(`packages/remote_driver_runtime/test/parity/android_tv_generic_parity_test.dart`), with no declared
differences.

Hardware verification is still required for every row.
