# TV provider capability audit

Baseline `7997ca2`. This matrix describes the driver surface after this audit.
Tested means a local protocol fixture exercised the operation. Physical verification
for the changes in this audit is pending for every provider.

| Code | Implementation and evidence |
| --- | --- |
| T | Implemented and exercised by an automated protocol fixture. The fixture does not establish physical support. |
| K | Implemented with driver-known evidence. The specific command was not fully exercised in a protocol fixture. |
| C | Conditional on the session, catalog, TV model, or firmware. The row describes the evidence. |
| U | Unsupported by this driver. No usable capability is emitted. |
| I | A protocol route may exist, but the driver needs additional validation or an operation matching the UI contract. |

Unless a row says otherwise, control evidence is **known**, even for operations
covered by fixtures. A successful status read can be **verified** for that read.
**Advertised** evidence comes from the device. The app requires known or verified
evidence to enable a control. **Unavailable** describes an operation that failed
or lost its prerequisites in the current session. **Unsupported** describes
an operation the driver does not offer. The audit distinguishes missing driver
implementation from confirmed protocol restrictions where evidence is available.

| Capability or contract members | LG webOS | Android TV / Google TV, including TCL | Samsung Tizen | Roku ECP, development only |
| --- | --- | --- | --- | --- |
| `press` | T/C · SSAP requests a pointer channel and the driver sends navigation frames | T/C · Remote v2 key injection (field 10), negotiated key bit; fixture covers Enter | T/C · `ms.remote.control`, fixture covers Enter | T · ECP keypress, fixture covers Select |
| `volumeUp`, `volumeDown` | T · `audio/volumeUp` and `audio/volumeDown` | T/C · keys 24/25, requires key support; fixture covers 24 | T/C · `KEY_VOLUP` and `KEY_VOLDOWN`; fixture covers up | T/C · VolumeUp/Down on TVs or devices with positive audio-control evidence; explicit false takes precedence |
| `setVolume` | T/C · `audio/setVolume`, disabled on explicit rejection | U · inbound level feedback does not authorize an absolute setter | U | U |
| `setMuted` | T/C · `audio/setMute`, disabled on explicit rejection | U · mute feedback does not establish a reliable set operation | U · mute toggle does not satisfy a requested mute state | U · ECP VolumeMute is a toggle |
| `readVolume`, `watchVolume` | C · SSAP getVolume and subscription; valid read verifies feedback | T/C · field 50 reports max, level and muted; valid report verifies feedback | U | U |
| `channelUp`, `channelDown` | K/C · SSAP TV channel commands | T/C · sends channel keys 166/167; depends on the active input or app | K/C · `KEY_CHUP` and `KEY_CHDOWN` | I · device and source dependent |
| `channels`, `selectChannel` | C · webOS channel list and tune commands | U | U | U |
| `sendMedia` | K/C · SSAP media.controls actions | K/C · Remote v2 key injection with negotiated key support; app may ignore a key | K/C · discrete Samsung media keys; app may ignore a key | U · individual Play/Pause are not exposed by this driver |
| `togglePlayback` | U · discrete actions available | U · discrete actions available | U · discrete actions available | T · ECP Play key toggles playback |
| `movePointer`, `scroll`, `click` | C · established webOS pointer channel | U | I · no supported pointer session in this integration | U |
| `sendKey` | C · pointer-channel keys | U | K/C · key mapping in driver, dash unsupported; no generic keypad exposed without appropriate item evidence | U |
| `sendText`, `sendEnter` | C · SSAP IME, focused field and app must accept input | I · IME negotiation and edit counters are unimplemented | Text U; Enter delegates to navigation | T/C · ECP Lit characters and Enter, requires keyboard context |
| `inputs`, `selectInput` | T/C · nonempty external input list and SSAP input selection | U | I · input keys do not supply a discoverable catalog | T/C · TV input IDs from ECP catalog with corresponding keys |
| `currentInput`, `currentInputChanges` | U | U | U | U |
| `applications`, `launchApplication`, `reportedApplicationIds` | T/C · nonempty SSAP list and launcher; firmware can reject particular launches | I · app-link launch does not provide an installed catalog | T/C · nonempty `ed.installedApp.get`; `ed.apps.launch` awaits the write, which does not confirm the TV opened the app | T/C · ECP list and launch; empty or denied list hides the catalog |
| `currentApplication`, `currentContent`, `watchCurrentContent` | C · foreground query/subscription and optional live-channel data | I · app/IME status signals need independent validation | U | T/C · verified active-app read; live subscription U |
| `powerOff` | T/C · `system/turnOff`; never probed during discovery | C · key 223 requires negotiated key and power support | T/C · `KEY_POWER` on connected remote channel | C · PowerOff, explicit device flag or older TV fallback |
| `canWake`, `wake` | C · Wake-on-LAN, configured or learned MAC | U · no established standby-wake path for this integration | C · Wake-on-LAN, configured or learned MAC and compatible standby settings | U |
| `bluetoothAccessories`, `toggleBluetoothAccessory` | C · compatible webOS accessory service, pairing managed by TV | U | U | U |
| `openAccessorySettings` | C · TV-reported settings app, opens sound settings | U · generic Android Settings key does not establish an accessory settings route | U | U |
| `startVoiceControl`, `toggleGameMode`, `syncWatchCompanion` | U | U | U | U |

## Identity, pairing and session behavior

- LG and Samsung accept their declared SSDP services. Samsung's secure remote
  channel is port 8002. Its approved certificate pin and token remain required
  where applicable. Transport write completion is the strongest launch outcome
  available here. The driver has no dependable per-command acknowledgment.
- Android recognizes `_androidtvremote2._tcp` on 6466. iOS uses the native Bonjour
  adapter and other platforms use Dart mDNS. Port 6467 supplies pairing and
  candidate certificate evidence. Missing certificate evidence yields a
  provisional profile. A compatible service or an advertised certificate does
  not establish authenticated identity. Pairing and pinned TLS establish that
  identity. Matching certificate evidence can correlate an address change.
- Roku validates the advertised service and location, checks its serial on
  connection, and remains opt-in for development builds. ECP permission or
  unsupported responses revoke only the associated session capability.
- All providers use existing typed controllers and retain their saved profile
  and credential formats. The UI reads the selected live driver's evidence.
  Session capability changes update controls without simulating a reconnect.

## Protocol references

- [Android Remote v2 protocol research and negotiated features](https://github.com/sonalder-darlene/libremote-android-tv/blob/main/PROTOCOL.md)
- [Android Remote v2 wire schema reference](https://github.com/tronikos/androidtvremote2/blob/main/src/androidtvremote2/remotemessage.proto)
- [Roku ECP commands and distribution restrictions](https://developer.roku.com/dev/docs/external-control-api)
