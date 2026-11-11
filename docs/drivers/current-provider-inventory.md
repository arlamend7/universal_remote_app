# Current provider inventory

Baseline commit `6314a30da63b2c0d483a47368c793319b1e07214`.

| Persisted provider ID | Discovery and transport | Behavior to preserve |
| --- | --- | --- |
| `lg.webos` | SSDP and local probes. SSAP over WebSocket with a separate pointer channel. | Certificate and connection settings, on-TV approval and client key, input and app commands, navigation, volume feedback, and MAC-based wake. |
| `android.tv` | Bonjour/mDNS, candidate certificate probe and Remote v2 over TLS. iOS uses native Bonjour. | Remote v2 binary framing and negotiated features, pairing and pinned identity, navigation, supported media and volume, and MAC-based wake. |
| `samsung.tizen` | SSDP and local identification probes. Secure remote WebSocket. | Pin and token handling, on-TV approval, navigation and supported app launch, model-dependent behavior, and MAC-based wake. |
| `roku.ecp` | SSDP and local ECP HTTP with serial checks. | Device and capability restrictions, command outcomes, and the development-only `ENABLE_ROKU_ECP` gate. |

The [capability audit](../provider-capability-audit.md) covers the command-level inventory and evidence. Firmware, device settings and negotiated capabilities affect availability. Automated fixtures do not establish physical-TV compatibility.

## Baseline validation

The clean checkout passed static analysis, the structure check, the dependency audit, and all 101 Dart package tests. The formatting gate flagged three files. The initial Flutter run passed 120 tests and failed seven because fixtures referenced a direction-pad variant or a volume slider removed from the latest default layout. The baseline repair updates those expectations and gives the no-feedback pairing fixture its own slider to retain that assertion.

After repair, the formatter reported no changes, static analysis and the structure check passed, and all 127 Flutter tests passed. The repair affects formatting and fixtures only.

## Managed bindings

LG webOS reads managed SSAP volume, mute and power mappings when a compatible signed package is installed. The adapter checks each binding against its approved SSAP path. Its compiled engine still owns registration, pairing, certificate behavior, capability negotiation, the pointer socket, apps, inputs and wake. The same fixture checks wire commands and capability behavior with and without managed bindings.

Android TV reads managed Remote v2 navigation, media, relative volume and power key mappings. The compiled adapter validates each key against its expected Android code and retains pairing, mutual TLS, certificate pinning, binary framing, feature negotiation and wake. The TLS fixture checks that a managed mapping and a rejected override emit the same binary keys as before.
