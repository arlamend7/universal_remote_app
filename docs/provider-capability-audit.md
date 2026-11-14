# TV provider capability audit

Baseline `7997ca2`, updated for commit `28db5b1`. This matrix describes the driver surface after this audit.
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
| `setVolume` | T/C · `audio/setVolume`, disabled on explicit rejection | T/C · absolute output mode and output ID required | U | U |
| `setMuted`, `toggleMute` | T/C · `audio/setMute`, disabled on explicit rejection; `toggleMute` reads the state and sets the opposite | T/C · explicit mute uses the latest report and sends a toggle when needed; `toggleMute` sends the mute key (164) | `setMuted` U · `toggleMute` K/C sends `KEY_MUTE` and gives no state | `setMuted` U · `toggleMute` T/C sends VolumeMute where audio control is reported |
| `readVolume`, `watchVolume` | C · SSAP getVolume and subscription; valid read verifies feedback | T/C · field 50 reports max, level and muted; valid report verifies feedback | U | U |
| `channelUp`, `channelDown` | K/C · SSAP TV channel commands | T/C · sends channel keys 166/167; depends on the active input or app | K/C · `KEY_CHUP` and `KEY_CHDOWN` | T/C · Roku TV channel keys, tuner-dependent |
| `channels`, `selectChannel` | C · webOS channel list and tune commands | U | U | C · read-only tuner list, direct tune U |
| `sendMedia` | K/C · SSAP media.controls actions; previous and next U | T/K/C · Remote v2 key injection with negotiated key support, including next and previous track (87/88, mapping tested); app may ignore a key | K/C · discrete Samsung media keys; previous and next U; app may ignore a key | T/C · Rewind and Fast Forward only; Play/Pause is a separate toggle |
| `togglePlayback` | U · discrete actions available | U · discrete actions available | U · discrete actions available | T · ECP Play key toggles playback |
| `movePointer`, `scroll`, `click` | C · established webOS pointer channel | U | I · no supported pointer session in this integration | U |
| `sendKey` | C · pointer-channel keys | T/K/C · digits, Menu, Info, Guide, Exit, colour keys, settings, input picker and mute (key codes tested); an app may ignore a key | T/C · numeric and special keys, source picker, settings (Menu key) and mute; dash unsupported | T/C · instant replay and mute where supported |
| `sendText`, `sendEnter` | C · SSAP IME, focused field and app must accept input | T/C · negotiated IME, focused field and reported submit action | Text U; Enter delegates to navigation | T/C · ECP Lit characters and Enter, requires keyboard context |
| `inputs`, `selectInput`, `openInputPicker` | T/C · nonempty external input list and SSAP input selection; `openInputPicker` U | C · `inputs` returns an empty list and `openInputPicker` sends the Source key (K) | C · `inputs` returns an empty list and `openInputPicker` sends `KEY_SOURCE` (T) | T/C · TV input IDs from ECP catalog with corresponding keys; `openInputPicker` U |
| `currentInput`, `currentInputChanges` | T/C · foreground HDMI app (`com.webos.app.hdmiN`) mapped to the input; changes follow content updates | U | U | T/C · active app matched against the TV input catalog; changes follow content reads |
| `applications`, `launchApplication`, `reportedApplicationIds` | T/C · nonempty SSAP list and launcher; `id?contentId=…` passes a content id and an http(s) address opens through `system.launcher/open`; firmware can reject particular launches | C · `applications` is empty; `launchApplication` accepts a supported app link only, requires negotiated app links | T/C · `ed.installedApp.get` list when the TV reports it; any well-formed app ID can launch, and `ed.apps.launch` awaits the write, which does not confirm the TV opened the app | T/C · ECP list and launch; empty or denied list hides the catalog |
| `currentApplication`, `currentContent`, `watchCurrentContent` | C · foreground query/subscription and optional live-channel data | T/C · foreground app package from IME reports | U | T/C · verified active-app read, optional tuner program and media feedback; live subscription U |
| `powerOff` | T/C · `system/turnOff`; never probed during discovery | T/C · negotiated key and power support. Key 223 by default, key 26 for the Smart TV Pro model profile | T/C · `KEY_POWER` on connected remote channel | C · PowerOff, explicit device flag or older TV fallback |
| `canWake`, `wake` | C · Wake-on-LAN, configured or learned MAC | C · Wake-on-LAN with a MAC learned after a connection; needs network wake on the TV (eligibility tested, send untested on hardware) | C · Wake-on-LAN, configured or learned MAC and compatible standby settings | I · ECP `PowerOn` on a Roku TV that reported power control; the key is absent from Roku's official list, so it may be ignored (fixture tested only) |
| `turnOffScreen`, `turnOnScreen` | U/C · `com.webos.service.tvpower/power/turnOffScreen` and `turnOnScreen`; unverified on hardware | U | U | U |
| `bluetoothAccessories`, `toggleBluetoothAccessory` | C · compatible webOS accessory service, pairing managed by TV | U | U | U |
| `openAccessorySettings` | C · TV-reported settings app, opens sound settings | U · use the separate Open TV settings action | U | U |
| `startVoiceControl` | U | U · the TV's voice session expects streamed audio, which this driver does not send | U | U |
| `toggleGameMode`, `syncWatchCompanion` | U | U | U | U |

`mute`, `inputs` and `applications` are single capabilities. A provider that can
only send a key or open the TV's own picker still reports the capability and
handles the difference itself: `toggleMute` for a mute key, an empty `inputs`
list plus `openInputPicker`, or an empty `applications` list plus launch by id
or link. Channel selection stays two capabilities because a list-only tuner
is different from one that can tune.

The [implementation progress audit](provider-capability-roadmap.md#implementation-progress)
describes setup, firmware checks, and the remaining research for the operations above.

## Identity, pairing and session behavior

- Wake: LG, Samsung and Android use Wake-on-LAN with a configured MAC or one
  learned after a connection. Roku sends the `PowerOn` key, which Roku's official list does not include. Wake outcomes for
  Android and Roku have not been checked on hardware.

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
