# Television API migration matrix

Baseline `f259d52`. Engine names in this table identify the intended typed runtime operation, with existing implementations listed in the linked [capability audit](../../provider-capability-audit.md). A dash means the baseline has no equivalent feature. Individual operations remain gated by device evidence.

| API members | LG | Android TV | Samsung | Roku |
| --- | --- | --- | --- | --- |
| Connect, disconnect, dispose and connection states | SSAP session | Remote v2 TLS session | Authorized WebSocket session | ECP identity and query session |
| Capability evidence and changes | SSAP probes and rejections | Negotiated flags and feedback | Session authorization and app response | Device flags and permission outcomes |
| Wake eligibility and wake | Wake-on-LAN | Wake-on-LAN | Wake-on-LAN | Conditional ECP power key |
| Power off | SSAP request | Negotiated binary key | Remote channel key | ECP key |
| Screen off and on | Conditional SSAP requests | — | — | — |
| Volume up and down | SSAP request | Binary keys | Remote channel keys | Conditional ECP keys |
| Set volume | Bounded SSAP request | Negotiated output update | — | — |
| Set mute and toggle mute | SSAP update and state read | Binary toggle and negotiated state | Toggle key only | Toggle key only |
| Read and watch volume | SSAP query and subscription | Volume report and event stream | — | — |
| Navigation and special keys | Pointer frames | Negotiated binary keys | Remote channel keys | ECP keys |
| Move, scroll and click | Pointer frames | — | — | — |
| Channel up and down | SSAP TV commands | Binary keys | Remote channel keys | Tuner keys |
| List and select channels | SSAP list and tune | — | — | Tuner list only |
| Send media action | SSAP media requests | Binary media keys | Remote channel media keys | Scan keys |
| Toggle playback and read playback state | — | — | — | ECP Play toggle and conditional media query |
| Send text and Enter | SSAP IME | Negotiated IME | Enter key only | Context-dependent ECP text and Enter |
| List and launch applications, reported IDs | SSAP catalog and launch | Link launch only | Installed apps and launch | ECP catalog and launch |
| List and select inputs, open picker | SSAP external inputs and selection | Picker key | Picker key | Conditional input catalog and selection |
| Current input and changes | Foreground HDMI evidence | — | — | Active app and input catalog |
| Current application, content and changes | Foreground subscription and optional channel detail | IME foreground evidence and stream | — | Active app read and optional media/tuner data |
| Bluetooth list, toggle and settings | Conditional SSAP accessory operations | — | — | — |
| Voice, game mode and watch sync | — | — | — | — |

Identity, security and persistence requirements are in the provider audits for [LG](lg-webos.md), [Android TV](android-tv.md), [Samsung](samsung-tizen.md), and [Roku](roku.md). This matrix establishes the baseline and the intended runtime boundaries. Physical-TV parity remains a separate validation gate.
