# Roku ECP parity matrix

Phase 0 baseline for migrating `RokuController` to the generic declarative driver runtime. Every row below is the acceptance contract for the migrated driver. Source: `packages/remote_driver_runtime/lib/src/adapters/roku/**` and `lib/src/ecp/**`. Cross-provider summary: [TV API matrix](tv-api.md), [capability audit](../../provider-capability-audit.md). Wire-level goldens for these rows (`packages/remote_driver_runtime/test/parity/roku_ecp_parity_test.dart`) are described in the [parity README](README.md).

## Header

| Item | Current behavior |
| --- | --- |
| Provider id | `roku.ecp` (`ProviderIdentity.roku.storageId`); managed package id `roku-ecp`, current source release `drivers/providers/roku-ecp/1.1.0` (operations `compiled.bindings`, `roku.ecp`). Target integration folder `drivers/providers/roku-ecp/roku-supported/`. |
| Protocol | Roku External Control Protocol over local HTTP. `GET /query/<name>` returns XML; `POST /keypress/<Key>` and `POST /launch/<appId>[?contentId=…&mediaType=…]` with `Content-Length: 0`. Path segments are URI-encoded. |
| Transport / ports | `http://<ipv4>:8060` only; host must be private IPv4 (10/8, 172.16/12, 192.168/16, 169.254/16). New `HttpClient` per request, no proxy (`DIRECT`), no redirects, 3 s connect and total timeout, response ≤ 512 KiB, documents containing `<!DOCTYPE` rejected. Plain HTTP is the protocol's only transport; there is no TLS to downgrade from. |
| Pairing / credential | None. No `CredentialStore` use; nothing under `client-key.v2.<deviceId>`. Access depends on the Roku "Control by mobile apps" setting (HTTP 401/403 → `permission`). |
| Certificate pinning | Not applicable (no TLS); `trustedCertificateDer` unused. Identity is the device serial. |
| Device-id formats | Discovery: `roku.ecp:<serial lower-case>` from USN `uuid:roku:ecp:<serial>`, name `Roku (<serial>)`, metadata `usn`, `rokuSerial`. Manual: `newProfileId()`, `stableIdentity:false`. After a connection the controller reports `reportedDiscoveryIdentity = uuid:roku:ecp:<serial>`, which the app stores as metadata `discoveryIdentity`. |
| Reconnection | No persistent session and no loss detection; `disconnect` only clears local state. Each `connect` re-reads `device-info` and re-checks the serial. |
| Wake | `POST /keypress/PowerOn` (not in Roku's official key list). Provider path works offline when the saved device's `capabilities` include `power`; controller path requires a connected session with `power` evidence. No Wake-on-LAN. |
| Software identification | `GET /query/device-info` at connect. Sets `source=protocolResponse`, `manufacturer=vendor-name`, `model=model-name`, `hardwareModel=model-number`, `operatingSystem="Roku OS"`, `operatingSystemVersion=software-version`, `buildNumber=software-build`, `identifiedAt`, `raw` (`vendor-name`, `model-name`, `model-number`, `software-version`, `software-build`, `is-tv`). Unknown: `softwareVersion`, `firmwareVersion`, `protocolVersion`. Legacy metadata `softwareVersion = software-version`. `category` = television if `is-tv == true`, else mediaPlayer. `sessionSoftwareInformation` only while connected. |
| Release restriction | Development only: registered by `TvProviderAdapters.create(enableRoku: !kReleaseMode && bool.fromEnvironment('ENABLE_ROKU_ECP'))` (`--dart-define=ENABLE_ROKU_ECP=true`). Release builds never register Roku, and the publication tool rejects Roku packages. The migration must keep both guards. |

Notation: paths in "New driver definition" are relative to `drivers/providers/roku-ecp/roku-supported/`. **cmd(cap, K)**: `POST /keypress/K`, allowed only when connected and `supports(cap)`, else `unsupported`; HTTP 401/403 → `permission`, other non-2xx → `unsupported`, `timeout` (3 s), `network` (IO), `protocol` (oversized). On `permission`/`unsupported` the capability moves to `unavailable` and `capabilityChanges` emits (only if the session generation is unchanged). **query**: `GET /query/<name>`; same HTTP errors plus `protocol` for invalid/DOCTYPE XML; never disables. `DriverBindings.select` only accepts the compiled fallback, so bindings cannot change a key. Tests are under `packages/remote_driver_runtime/test/adapters/roku/` plus `packages/remote_driver_runtime/test/tv_provider_adapters_test.dart`.

## Operation matrix

| Original controller method | Protocol behavior (exact wire message: SSAP URI + payload, Android KeyEvent code / Remote v2 message, Samsung KEY_* / launch message, Roku ECP path) | Parameters & validation | Return model | Authentication | Stream behavior | Error handling (codes thrown, capability disabled on failure?) | New driver definition | New runtime operation | Test coverage | Parity status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `connect` | `GET /query/device-info`; then concurrently `GET /query/apps`, content probe (`GET /query/active-app` …), and if TV `GET /query/tv-channels` | Only from `disconnected`; `serial-number` must match `^[a-z0-9-]+$` under root `device-info` (`protocol`); must equal metadata `rokuSerial` or last `:` segment of `discoveryIdentity`, case-insensitive (`identity`); superseded → `cancelled` | `void`; states connecting → connected (no pairing state) | None | `connectionStates` broadcast | query errors from `device-info`; apps, content and channel failures ignored; failure → `disconnect()` | `workflows/identify-software.json`, `manifest.json#operations` | `identify-software` (+ `list-applications`, `read-content`, `list-channels` probes) | `roku/roku_controller_test.dart` (identifies a TV; streaming player), `roku/roku_launch_state_test.dart` (model and software version) | pending |
| `disconnect` | None (stateless HTTP) | — | `void`; state disconnected | — | Clears capabilities, catalog, TV flags | none | — | — (session close) | none dedicated | pending |
| `dispose` | `disconnect()` then close state, capability and input streams; idempotent | — | `void` | — | Streams closed | none | — | — (session close) | none dedicated (tear-down only) | pending |
| `evidence` / `supports` / `capabilityChanges` | No wire; from `device-info` flags and probes (evidence table) | — | `List<CapabilityEvidence>` (unavailable entries first) | — | `capabilityChanges` emits when a command revokes a capability | — | `capabilities.json` | — (capabilities.json evaluation) | `roku/roku_controller_test.dart` (403 revokes volume only; player capability set) | pending |
| `readWakeAddress` | Not implemented | — | — | — | — | — | not defined | none in vocabulary | none | pending |
| `submitPairingCode` | Not implemented (no pairing) | — | — | — | — | — | not defined | `pair` (absent) | none | unsupported (preserve) |
| `powerOff` | cmd(power, `PowerOff`) | — | `void` | None | — | cmd errors; disables `power` | `mappings.json#power-off` | `power-off` | none | pending |
| `wake` | Controller: cmd(power, `PowerOn`). Provider `wakeDevice`: `POST /keypress/PowerOn` without a session | Controller needs connection + `power`; provider needs saved `capabilities ∋ power` and an endpoint, else `wakeUnavailable` | `void` | None | — | cmd errors; provider: HTTP errors, `wakeUnavailable` | `mappings.json#wake` + provider wake policy | `wake` | `roku/roku_wake_test.dart` (PowerOn sent; refused without power) | pending |
| `canWake` | No wire; `supports(power)` (false when disconnected) | — | `bool` | — | — | — | `capabilities.json#wake` | `wake` (availability) | `roku/roku_wake_test.dart` (provider `canWakeDevice`) | pending |
| `volumeUp` | cmd(volume, `VolumeUp`) | — | `void` | None | — | cmd errors; disables `volume` | `mappings.json#volume-up` | `volume-up` | `roku/roku_controller_test.dart` (403 → `permission`, volume revoked) | pending |
| `volumeDown` | cmd(volume, `VolumeDown`) | — | `void` | None | — | cmd errors; disables `volume` | `mappings.json#volume-down` | `volume-down` | none | pending |
| `setVolume` | None | — | — | — | — | `unsupported` | not defined | `set-volume` (must stay absent) | `roku/roku_controller_test.dart` (absoluteVolume unsupported) | unsupported (preserve) |
| `setMuted` | None | — | — | — | — | `unsupported` | not defined | `set-mute` (must stay absent) | none | unsupported (preserve) |
| `toggleMute` | `sendKey(mute)` → cmd(mute, `VolumeMute`) | — | `void` | None | — | cmd errors; disables `mute` | `mappings.json#toggle-mute` | `toggle-mute` | `roku/roku_controller_test.dart` (VolumeMute via sendKey) | pending |
| `readVolume` | None | — | — | — | — | `unsupported` | not defined | `read-volume` (must stay absent) | none | unsupported (preserve) |
| `watchVolume` | None | — | empty stream | — | Never emits | none | not defined | `read-volume` (absent; no `volume` subscription) | none | pending |
| `press(up)` | cmd(navigation, `Up`) | — | `void` | None | — | cmd errors; disables `navigation` | `mappings.json#navigation-up` | `navigation-up` | none | pending |
| `press(down)` | cmd(navigation, `Down`) | — | `void` | None | — | as above | `mappings.json#navigation-down` | `navigation-down` | none | pending |
| `press(left)` | cmd(navigation, `Left`) | — | `void` | None | — | as above | `mappings.json#navigation-left` | `navigation-left` | none | pending |
| `press(right)` | cmd(navigation, `Right`) | — | `void` | None | — | as above | `mappings.json#navigation-right` | `navigation-right` | none | pending |
| `press(enter)` | cmd(navigation, `Select`) | — | `void` | None | — | as above | `mappings.json#navigation-enter` | `navigation-enter` | `roku/roku_controller_test.dart` (`Select`) | pending |
| `press(back)` | cmd(navigation, `Back`) | — | `void` | None | — | as above | `mappings.json#navigation-back` | `navigation-back` | none | pending |
| `press(home)` | cmd(navigation, `Home`) | — | `void` | None | — | as above | `mappings.json#navigation-home` | `navigation-home` | none | pending |
| `channelUp` | cmd(channels, `ChannelUp`) | `channels` only on Roku TVs | `void` | None | — | cmd errors; disables `channels` | `mappings.json#channel-up` | `channel-up` | `roku/roku_controller_test.dart` (`ChannelUp`) | pending |
| `channelDown` | cmd(channels, `ChannelDown`) | as above | `void` | None | — | as above | `mappings.json#channel-down` | `channel-down` | none | pending |
| `channels` | `GET /query/tv-channels` | Requires `is-tv` and `channelCatalog` evidence else `unsupported` | `List<DeviceChannel(number, name ?? number, number)>`; root `tv-channels`, ≤ 512 entries, `user-hidden=true` and entries without `number` skipped | None | — | query errors (no disable) | `mappings.json#list-channels` | `list-channels` | `roku/roku_controller_test.dart` (7.1) | pending |
| `selectChannel` | None | — | — | — | — | `unsupported` | not defined | `select-channel` (must stay absent) | none | unsupported (preserve) |
| `sendMedia(play, pause, stop)` | None (play/pause is the separate `togglePlayback`) | — | — | — | — | `unsupported` | not defined | `media-play`, `media-pause`, `media-stop` (must stay absent) | `roku/roku_controller_test.dart` (play unsupported) | unsupported (preserve) |
| `sendMedia(rewind)` | cmd(playbackScan, `Rev`) | — | `void` | None | — | cmd errors; disables `playbackScan` | `mappings.json#media-rewind` | `media-rewind` | `roku/roku_controller_test.dart` (`Rev`) | pending |
| `sendMedia(fastForward)` | cmd(playbackScan, `Fwd`) | — | `void` | None | — | as above | `mappings.json#media-fast-forward` | `media-fast-forward` | none | pending |
| `sendMedia(previous, next)` | None | — | — | — | — | `unsupported` | not defined | `media-previous`, `media-next` (must stay absent) | none | unsupported (preserve) |
| `togglePlayback` | cmd(playbackToggle, `Play`) | — | `void` | None | — | cmd errors; disables `playbackToggle` | `mappings.json#toggle-playback` | `toggle-playback` | `roku/roku_controller_test.dart` (`Play`) | pending |
| `playbackState` | `GET /query/media-player` | No capability or connection check | `true` for `<player state="play">`, `false` for `pause`, otherwise or on any error `null` | None | — | Errors swallowed → `null` | `mappings.json#read-playback` | `read-playback` | `roku/roku_launch_state_test.dart` (play/pause/buffer/empty) | pending |
| `turnOffScreen` | None (default) | — | — | — | — | `unsupported` | not defined | `screen-off` (must stay absent) | none | unsupported (preserve) |
| `turnOnScreen` | None (default) | — | — | — | — | `unsupported` | not defined | `screen-on` (must stay absent) | none | unsupported (preserve) |
| `movePointer` | None | — | — | — | — | `unsupported` | not defined | `pointer-move` (must stay absent) | none | unsupported (preserve) |
| `scroll` | None | — | — | — | — | `unsupported` | not defined | `pointer-scroll` (must stay absent) | none | unsupported (preserve) |
| `click` | None | — | — | — | — | `unsupported` | not defined | `pointer-click` (must stay absent) | none | unsupported (preserve) |
| `sendKey(mute)` | cmd(mute, `VolumeMute`) | — | `void` | None | — | cmd errors; disables `mute` | `mappings.json#key-mute` | `key-mute` | `roku/roku_controller_test.dart` (`VolumeMute`) | pending |
| `sendKey(replay)` | cmd(instantReplay, `InstantReplay`) | — | `void` | None | — | cmd errors; disables `instantReplay` | `mappings.json#key-replay` | `key-replay` | none | pending |
| `sendKey(digit0…digit9, dash, enter, menu, info, guide, exit, red, green, yellow, blue, source, settings, liveTv, captions)` | None | — | — | — | — | `unsupported` | not defined | matching `key-*` ids (must stay absent) | none | unsupported (preserve) |
| `sendText` | One cmd(textInput, `Lit_<char>`) per Unicode code point, sequential (`/` is sent as `Lit_%2F`) | ≤ 256 code points else `text`; empty text sends nothing; stops silently if the session generation changes | `void` | None | — | cmd errors; a failing character disables `textInput` | `mappings.json#send-text` | `send-text` | `roku/roku_controller_test.dart` (`Lit_%2F`) | pending |
| `sendEnter` | cmd(textInput, `Enter`) | — | `void` | None | — | cmd errors; disables `textInput` | `mappings.json#send-enter` | `send-enter` | none | pending |
| `inputs` | No wire; entries of the cached `/query/apps` catalog with ids `tvinput.dtv`, `tvinput.hdmi1`–`4`, `tvinput.cvbs` | — | `List<DeviceInput(id, text)>`; `[]` without a catalog | None | — | none | `mappings.json#list-inputs` | `list-inputs` | `roku/roku_controller_test.dart` | pending |
| `selectInput` | cmd(inputs, `InputTuner` / `InputHDMI1`…`InputHDMI4` / `InputAV1`) for the ids above | Id must be in the cached input list else `unsupported` | `void` | None | — | cmd errors; disables `inputs` | `mappings.json#select-input` | `select-input` | `roku/roku_controller_test.dart` (`InputHDMI1`) | pending |
| `openInputPicker` | None (default) | — | — | — | — | `unsupported` | not defined | `open-input-picker` (must stay absent) | none | unsupported (preserve) |
| `currentInput` | No wire; active-app id matched against the cached input list during `currentContent` | — | `DeviceInput?` | None | — | none | `mappings.json#read-input` | `read-input` | `roku/roku_controller_test.dart` (HDMI 1 then null) | pending |
| `currentInputChanges` | Same; updated only when `currentContent` runs while connected | — | `Stream<DeviceInput?>` | None | Broadcast; emits only on change (including `null`); no push | none | `mappings.json#read-input` + subscription `input` (poll-based) | `read-input` (+ subscription `input`) | `roku/roku_controller_test.dart` | pending |
| `applications` | No wire; catalog cached at connect from `GET /query/apps` (not re-queried) | Root `apps`; numeric ids with non-blank names only | `List<DeviceApplication(id, name, artwork = /query/icon/<id>)>`; `[]` without a catalog | None | — | none | `mappings.json#list-applications` | `list-applications` | `roku/roku_controller_test.dart` (name decoding, icon path) | pending |
| `launchApplication` | cmd(applications) as `POST /launch/<id>` or `POST /launch/<id>?contentId=<c>[&mediaType=<t>]` | Id must be in `reportedApplicationIds` else `unsupported`; query only `contentId` (1–254 chars, required) and optional `mediaType` ∈ {series, season, episode, movie, shortFormVideo, tvSpecial}, else `unsupported` | `void` | None | — | cmd errors; disables `applications` | `mappings.json#launch-application` | `launch-application` | `roku/roku_controller_test.dart`, `roku/roku_launch_state_test.dart` (deep link; malformed or unknown links) | pending |
| `currentApplication` | `currentContent().appId` | — | `String?` | None | — | as `currentContent` | `mappings.json#read-application` | `read-application` | none | pending |
| `reportedApplicationIds` | No wire; ids of the cached catalog | `null` without a catalog | `Set<String>?` | — | — | none | `mappings.json#list-applications` (cached ids) | `list-applications` | none | pending |
| `currentContent` | `GET /query/active-app`; when connected and tuner feedback exists `GET /query/tv-active-channel`; otherwise `GET /query/media-player` | No capability check; root `active-app` and non-blank `<app>` text required (`protocol`); app id default `roku.home` | `CurrentContent(appId, appName)`; live TV (`active-input=true`) adds `liveTv`, `channelNumber`, `channelName`, `programTitle`; player plugin id == app id adds `position`/`duration` (`<n> ms`) | None | — | active-app query errors propagate; channel and player failures ignored; never disables | `mappings.json#read-content` | `read-content` | `roku/roku_controller_test.dart` (live channel and program) | pending |
| `watchCurrentContent` | None | — | empty stream | — | Never emits (no subscription) | none | not defined | `read-content` (absent `content` subscription) | none | pending |
| `bluetoothAccessories` | None (default) | — | — | — | — | `unsupported` | not defined | `list-accessories` (must stay absent) | none | unsupported (preserve) |
| `toggleBluetoothAccessory` | None (default) | — | — | — | — | `unsupported` | not defined | `toggle-accessory` (must stay absent) | none | unsupported (preserve) |
| `openAccessorySettings` | None (default) | — | — | — | — | `unsupported` | not defined | `open-accessory-settings` (must stay absent) | none | unsupported (preserve) |
| `startVoiceControl` | None (default) | — | — | — | — | `unsupported` | not defined | none (must stay absent) | none | unsupported (preserve) |
| `toggleGameMode` | None (default) | — | — | — | — | `unsupported` | not defined | none (must stay absent) | none | unsupported (preserve) |
| `syncWatchCompanion` | None (default) | — | — | — | — | `unsupported` | not defined | none (must stay absent) | none | unsupported (preserve) |
| `sessionSoftwareInformation` / identity getters | From connect-time `device-info` | Only while connected; `reportedDiscoveryIdentity = uuid:roku:ecp:<serial>`; `verifiedPeerIdentity = null` | `DeviceSoftwareInformation` (header) | None | — | none | `workflows/identify-software.json` | `identify-software` | `roku/roku_launch_state_test.dart`, `roku/roku_controller_test.dart` (discovery identity) | pending |

## Capability evidence

`is-tv` is `true` only when `<is-tv>` text is exactly `true`. `supports-*` flags: `true`/`false` (trimmed) win; missing or other values default to `is-tv`.

| Capability | Availability | Condition / probe |
| --- | --- | --- |
| `navigation`, `textInput`, `playbackToggle`, `playbackScan`, `instantReplay` | known | Always after a successful `device-info` identity check. |
| `channels` | known | `is-tv`. |
| `channelCatalog` | known | `is-tv` and `GET /query/tv-channels` yields ≥ 1 visible channel at connect. Also enables tuner feedback in `currentContent`. |
| `mute`, `volume` | known | `supports-audio-volume-control` (default `is-tv`). |
| `power` | known | `supports-tv-power-control` (default `is-tv`). Persisted device `capabilities ∋ power` enables offline provider wake. |
| `applications` | known | `/query/apps` catalog has ≥ 1 numeric-id app. |
| `currentContent` | verified | The connect-time `active-app` probe returned a valid app. |
| `inputs`, `currentInput` | known | `is-tv` and the catalog contains ≥ 1 `tvinput.*` id from the input table. |
| Any of the above | unavailable | A cmd for that capability returned `permission` or `unsupported`; cleared on reconnect. |
| `media`, `trackNavigation`, `numericKeys`, `specialKeys`, `tvSettings`, `liveTvKey`, `captionsKey`, `channelSelection`, `absoluteVolume`, `volumeFeedback`, `pointer`, `screenPower`, `wake`, `bluetoothAccessories`, `accessorySettings`, `voice`, `gameMode`, `watch` | not reported | `channelSelection` stays absent: the tuner list is read-only. |

## Provider policies

| Policy | Current behavior |
| --- | --- |
| Registration | Only when `enableRoku` (`!kReleaseMode && ENABLE_ROKU_ECP`); see release restriction. Tested by `tv_provider_adapters_test.dart`. |
| Manual setup | Label `Roku (local HTTP)`; advanced setup hidden. Address must be private IPv4 (`FormatException` "Enter the Roku's local IPv4 address."). Endpoint `http://<ip>:8060`. Empty name → `Roku`. New id `newProfileId()`, category mediaPlayer, manufacturer `Roku`; editing keeps the id and replaces name and endpoint. Legacy, certificate, MAC and broadcast inputs are ignored. |
| Network configuration view | address only. |
| Controller creation | Provider must match and the single endpoint must equal `http://<private ipv4>:8060`, else `setup`. |
| Certificate review | None (no `DeviceConnectionPolicy`); registry returns false. |
| sameConnection | Registry default: same id, provider and endpoints. |
| Retry after wake | Registry default: false. |
| mergeDiscovered | Registry default: discovered device with saved name and metadata `{...discovered, ...saved}` (id follows discovery serial). |
| Discovery | SSDP service type and ST `roku:ecp`; USN `uuid:roku:ecp:<serial>`; private IPv4 host; `LOCATION` must be exactly `http://<host>:8060` or `http://<host>:8060/`. Address recognition and saved-device probe both read `device-info` and compare the serial. Tested by `roku/roku_discovery_test.dart`. |
| Wake provider | `canWakeDevice`: provider matches and saved `capabilities` contains `power`. `wakeDevice`: `POST /keypress/PowerOn`; otherwise `wakeUnavailable`. |

## Hardware verification

All rows are fixture-verified only (loopback HTTP servers). Check on a Roku TV and a Roku streaming player:

- "Control by mobile apps" off / limited / permissive and the resulting 401/403 per endpoint.
- `device-info` flags (`is-tv`, `supports-audio-volume-control`, `supports-tv-power-control`) and `software-version`/`software-build` formats.
- `PowerOn` from fast-start and deep standby (not an official key), `PowerOff`.
- `Lit_` text for non-ASCII characters, `Enter`, `InstantReplay`, `Rev`/`Fwd`, `Play` toggle.
- `/query/apps` input entries (`tvinput.*`) and `Input*` keys; `/query/tv-channels`, `tv-active-channel` and `media-player` fields on tuner and streaming content.
- Deep-link launch parameters per channel app.
