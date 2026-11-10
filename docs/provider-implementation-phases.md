# Provider implementation phases

Each item from the "can add now" and "needs evidence" lists, with the public
protocol evidence found for it and what was done. **Evidence** names the source
(Roku ECP reference, `tronikos/androidtvremote2`, ConnectSDK / `aiowebostv`,
`xchwarze/samsung-tv-ws-api`). Nothing here has been tried on a real TV.

| Phase | Provider | Item | Evidence | Outcome |
| --- | --- | --- | --- | --- |
| 0 | Android TV | Voice (assistant key) | The reference library's voice session expects streamed audio; no evidence that key 231 works alone | **Removed** |
| 0 | Roku | Wake with `PowerOn` | `PowerOn` is not in Roku's official key list | Kept, relabelled unverified |
| 1 | Roku | Real playback state | `query/media-player` returns `state="play"`; other state values are not documented | Implemented: `play` and `pause` only |
| 1 | Roku | Play/pause toggle with state | Uses the documented `Play` key plus the state above | Implemented |
| 1 | Roku | Deep-link launch | `launch/{id}?contentId=&mediaType=` is documented | Implemented |
| 1 | Roku | Device model and firmware | `device-info` documents `model-name`, `software-version` | Implemented |
| 1 | Roku | Search a title | `search` was removed in Roku OS 12 | Not implemented |
| 1 | Roku | Info / Search keys | Documented, but no capability fits them without exposing unrelated controls | Deferred |
| 1 | Roku | Standby state | Only `power-mode="PowerOn"` is documented | Deferred |
| 2 | Android TV | Live TV (170) and Captions (175) keys | Key codes in `remotemessage.proto` | Implemented |
| 2 | Android TV | Launch by package id | The reference library sends `market://launch?id=<id>` for a bare id | Implemented |
| 2 | Android TV | Screen on/off state | `RemoteStart.started` (field 40) | Deferred: no cross-provider consumer yet |
| 2 | Android TV | Find My Remote | No such message in the proto or library | Blocked |
| 3 | LG webOS | Launch with content id, open a URL | `system.launcher/launch` with `contentId`; `system.launcher/open` with `target` | Implemented |
| 3 | LG webOS | Screen off / on | `com.webos.service.tvpower/power/turnOffScreen` and `turnOnScreen` | Implemented |
| 3 | LG webOS | TV details | `getSystemInfo` and `getCurrentSWInformation` exist; returned fields are not documented | Implemented defensively |
| 3 | LG webOS | Sound output | URIs documented; allowed values are not | Deferred |
| 3 | LG webOS | Channel by number | `tv/openChannel` accepts `channelNumber`; no control needs it | Deferred |
| 3 | LG webOS | Picture mode, sleep timer, game mode, voice, direct Bluetooth pairing, playback title and time | No evidence in any source | Blocked |
| 3 | Samsung | Text input | Message shape known, but the surrounding envelope was not verified | Deferred |
| 3 | Samsung | Pointer | `Move` shape known, but whether it is absolute or relative is not | Deferred |
| 3 | Samsung | Direct HDMI keys | Only `KEY_HDMI` (cycles) is listed, not `KEY_HDMI1..4` | Not needed |
| 3 | Samsung | Current app, volume level | Not present in any source | Blocked |
| 4 | All | Play/Stop toggle | Uses the existing discrete Play and Stop commands | Implemented |
| 4 | All | Multi-step buttons | Needs its own design | Deferred |
