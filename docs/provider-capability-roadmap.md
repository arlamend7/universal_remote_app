# What Universal Remote can add next

This audit complements the [current capability matrix](provider-capability-audit.md).
It describes proposed work. Each operation has its own prerequisites and hardware
test. A command accepted for sending and a change confirmed by the TV are
separate outcomes.

**Add** means there is a concrete implementation path. **Try** means a command
can be offered as an explicit test on a selected device. **Research** means a
required part of the interface still needs evidence.

## Android TV / Google TV, including compatible TCL models

| Feature | Status | Implementation and validation |
| --- | --- | --- |
| Channel +/− | Already added | Send keys 166/167 through Remote v2. Test on TCL's built-in Live TV and distinguish tuner, streaming app, and HDMI sources. |
| Open TV settings, input picker, numeric keys | Try | Send documented Android key codes through the existing negotiated key channel. Validate each control on the selected device. Expose an input picker action separately from input enumeration or direct HDMI switching. |
| Mute toggle and explicit mute state | Add, conditional | Negotiate volume support and retain the audio device ID and mute state from the latest report. Send field 51 to toggle. An explicit mute or unmute requires fresh state and a follow-up report before claiming success. |
| Absolute volume | Add, conditional | Retain the output ID, minimum, maximum, and reported control mode from field 50. Enable a slider only for an output reporting absolute control. Send the documented level request for that output and use the next report as feedback. |
| Keyboard and submit | Add, conditional | Negotiate IME. Track focused field ID, text counter, and selection. Send field 21 edits and submit only when the field reports an appropriate editor action. Clear state when focus moves and keep typed text out of logs. |
| Foreground app | Add, conditional | Use the package identifier in IME editor information where reported. Label it as foreground app only, with a package-name fallback. Validate how promptly it changes on real TVs. |
| Saved app or content shortcuts | Add, conditional | Negotiate app-link support and send field 90 for a user-selected or curated link. Leave app installation off and handle a rejected link or lost session. An app-link shortcut is separate from an installed-app picker. |
| Screen state and remote finder | Research | Evaluate power reports and the optional Find My Remote feature on hardware that advertises it. |
| Wake from standby | Research | Some standby advertisements include a wake port. Confirm its handshake, authorization, and availability on the target model before enabling wake. |
| Tuner list, direct tuning, HDMI inventory, Bluetooth accessory control | Research | The existing Remote v2 provider has no established API for these operations. The settings shortcut can reach the TV menus. Investigate a separately authorized integration where the model exposes one. |

Sources: [Android key definitions](https://developer.android.com/reference/android/view/KeyEvent),
[Remote v2 protocol research](https://github.com/sonalder-darlene/libremote-android-tv/blob/main/PROTOCOL.md),
[TCL settings guide](https://support.tcl.com/en_US/us-googletv-setup-configuration/tcl-google-tv-settings-and-user-manual-guide).

## LG webOS

| Feature | Status | Implementation and validation |
| --- | --- | --- |
| Reported app artwork | Add, conditional | Preserve usable artwork returned in the existing SSAP catalog. Validate and size-limit URLs; use the existing fallback when the TV supplies a path the phone cannot access. |
| Current HDMI input | Research | Compare current foreground and external-input responses on a real TV. Only expose an input name after a reliable mapping to a reported input ID. |
| Better channel and audio coverage | Add, conditional | Exercise existing SSAP channel list/tune, relative volume, absolute volume, and mute independently on target firmware. Expose each operation according to its own evidence and keep relative volume if a different audio command is rejected. |
| Bluetooth soundbar shortcuts | Already available on compatible firmware | Use the existing paired-device service. Validate list, connect, disconnect, and status independently. Keep TV settings as the path for initial pairing. |
| Direct Bluetooth pairing, app playback title/time, picture controls | Research | Require a documented or captured authorized operation and test against the specific TV and app. Foreground app and broadcast channel data do not establish streaming playback data. |

Source: [Connect SDK webOS service implementation](https://github.com/ConnectSDK/Connect-SDK-Android-Core/blob/master/src/com/connectsdk/service/WebOSTVService.java).

## Samsung Tizen

| Feature | Status | Implementation and validation |
| --- | --- | --- |
| Numeric and special keys | Add, conditional | Expose existing mapped keys with a dedicated capability. Enable only the keys the driver actually sends. Test tuner digits and remote keys independently. |
| Source picker and mute toggle | Try | Test source and mute keys on the existing pinned WebSocket. Expose them as single actions and avoid inferring an input list or mute state from a keypress. |
| App shortcuts | Add, conditional | Improve catalog parsing and validate launch behavior on supported firmware. Keep a distinct shortcut path for confirmed launch targets on models where catalog discovery is unavailable. |
| Text entry | Research | Capture and validate Samsung keyboard focus, text frames, and submission over the authorized connection. Test in several TV apps. |
| Absolute volume, audio feedback, current app, input or channel lists | Research | Validate a separate Samsung interface where available. Tizen APIs intended for apps running on the TV do not establish remote WebSocket support. |
| Standby wake | Already available on compatible firmware | Test existing Wake-on-LAN with the configured TV MAC and Power On with Mobile enabled. |

Sources: [Samsung Tizen application API](https://developer.samsung.com/smarttv/develop/api-references/tizen-web-device-api-references/application-api.html),
[Samsung IP control settings](https://image-us.samsung.com/SamsungUS/samsungbusiness/tv-ci-resources/Samsung-IP-Control.pdf).

## Roku ECP — authorized development testing only

| Feature | Status | Implementation and validation |
| --- | --- | --- |
| Channel +/− | Add, conditional | Send ECP ChannelUp and ChannelDown on Roku TV. Validate against the tuner input. Keep streaming players ineligible. |
| Channel list and current broadcast program | Add, conditional | Parse query/tv-channels and query/tv-active-channel. Keep the list read-only until there is a tested tuning operation. Show channel or program details only when returned and the tuner input is active. |
| Rewind, Fast Forward, Replay, and Mute toggle | Add, conditional | Expose documented Rev, Fwd, InstantReplay, and VolumeMute independently. Keep mute limited to supported audio devices and preserve the existing native Play/Pause toggle. |
| App artwork and media feedback | Add, conditional | Load bounded app icons from query/icon and parse query/media-player when the device returns useful fields. Confirm which streaming apps report usable position or duration. |
| Direct tuning, exact volume, wake, Bluetooth control | Research | Require an authorized, device-specific command with evidence. Keep the existing development gate. |

Source: [Roku ECP reference and third-party restrictions](https://developer.roku.com/dev/docs/external-control-api).

## Implementation checks

- Reuse existing provider controllers and the shared dashboard catalog. Separate
  picker keys from catalogs and toggles from absolute setters.
- For an explicit device trial, report **Command sent** and let the user confirm
  whether the TV responded. Avoid automatic tests that change channels, power,
  inputs, or audio.
- Verify exact frames with local fixtures, check unavailable states and reconnect,
  then record the physical TV model, firmware, input/app, and result.
- Keep pairing and TLS verification in place. A phone-to-TV Bluetooth
  connection is not required for the Android Remote v2 work above.
