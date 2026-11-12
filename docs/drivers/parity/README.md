# Provider parity baseline

This folder is the feature-parity contract for the migration from manufacturer
controllers to one declarative driver runtime. Legacy code may only be removed
when the generic runtime reproduces every row here.

| File | Contents |
|---|---|
| [lg-webos.md](lg-webos.md) | LG webOS (SSAP + pointer socket) per-operation matrix |
| [android-tv.md](android-tv.md) | Android TV / Google TV (Remote v2) matrix |
| [samsung-tizen.md](samsung-tizen.md) | Samsung Tizen (secure WebSocket channel) matrix |
| [roku.md](roku.md) | Roku ECP matrix (development-only distribution) |
| [tv-api.md](tv-api.md) | Cross-provider `TVRemoteBase` summary |

## Executable baseline (wire-level goldens)

Every matrix row is also pinned by a recorded transcript of what the legacy
controller actually sends and returns:

| Provider | Test | Golden | Fixture |
|---|---|---|---|
| LG webOS | `packages/remote_driver_runtime/test/parity/lg_webos_parity_test.dart` | `test/parity/golden/lg_webos.json` | Fake SSAP + pointer sockets (`standard_responses.dart`) |
| LG webOS (conditional) | `lg_webos_conditional_parity_test.dart` | `lg_webos_conditional.json` | Volume feedback rejected, settings app present, live TV foreground, no inputs, Bluetooth rejected, webOS 7 software |
| Android TV | `android_tv_parity_test.dart` | `android_tv.json` | Loopback TLS Remote v2 endpoint offering keys, IME, volume and app links |
| Samsung Tizen | `samsung_tizen_parity_test.dart` | `samsung_tizen.json` | Authorized secure channel issuing a token |
| Roku ECP | `roku_ecp_parity_test.dart` | `roku_ecp.json` | Loopback ECP HTTP server answering every documented query |

The shared scenario (`test/parity/support/tv_parity_steps.dart`) calls every
public `TVRemoteBase`/`RemoteBase` member in a fixed order — each navigation
key, media action and remote key individually — and records:

- the exact outgoing wire frames (SSAP JSON without volatile request ids,
  pointer frames, decoded Remote v2 protobuf fields, Samsung channel JSON,
  ECP `METHOD path?query`), plus wake and transport-open events;
- the returned value (normalized JSON) or the `RemoteException` code;
- reported capability evidence and identified software before and after
  disconnecting.

Goldens were recorded once from the legacy controllers
(`UPDATE_PARITY_GOLDENS=1 dart test test/parity`). They must never be
re-recorded to make a migrated implementation pass; a generic-runtime test
compares its transcript with the same file.

## Compatibility evidence found in the legacy code

| Provider | Software evidence read today | Version-dependent behavior today | Integration families |
|---|---|---|---|
| LG webOS | `ssap://com.webos.service.update/getCurrentSWInformation` → `model_name`, `product_name` (e.g. `webOSTV 5.0`), `sw_type`, `major_ver`, `minor_ver`. Firmware = `major.minor` when `sw_type` is `FIRMWARE`. **The webOS version is never parsed** (`operatingSystemVersion` stays null). | None. Transport is chosen per device (wss:3001 default, ws:3000 explicit legacy opt-in), not by version. | Split by user decision into `lg.webos.22-plus` (webOS ≥ 7, reported `product_name` `webOSTV 7.x` or later) and `lg.webos.legacy` (webOS < 7). Both start from identical command behavior. Parsing `product_name` into `operatingSystemVersion` is a new declarative identification rule; the `webOS 22 = webOSTV 7.x` mapping is unverified on hardware. |
| Android TV | None from the TV. The session reports `operatingSystem: Android TV`, `protocolVersion: Remote v2`. Negotiated Remote v2 features (keys, power, volume, IME, app links) gate capabilities. | Feature negotiation only. | One integration, `android.tv.remote-v2`. OS/firmware stay unknown. |
| Samsung Tizen | None (no device-info query). | None. | One integration, `samsung.tizen.supported`. Model/firmware stay unknown; no year-based inference. |
| Roku ECP | `query/device-info` → vendor, model name/number, `software-version`, `software-build`, `is-tv`, `supports-audio-volume-control`, `supports-tv-power-control`. | Device-info flags gate volume/mute/power; `is-tv` gates channels and inputs. | One integration, `roku.ecp.supported`, development channel only. |
