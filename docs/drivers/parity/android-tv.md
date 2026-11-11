# Android TV and Google TV parity audit

Baseline `f259d52`. The [TV API matrix](tv-api.md) lists all existing capability methods and their target operations.

| Area | Existing behavior to preserve | Target |
| --- | --- | --- |
| Discovery and identity | Bonjour service `_androidtvremote2._tcp`, native iOS adapter, certificate probe and provisional identity when no certificate is available. | Declarative service matching with existing candidate certificate inspection and profile reconciliation. |
| Pairing and session | PIN challenge on 6467. Client certificate, pairing proof and pinned Remote v2 TLS on 6466. Key, volume, IME and link messages use bounded binary framing. | Retain a typed compiled Remote v2 engine, session and credential format. |
| Feedback and errors | Feature negotiation gates keys and app links. Device frames provide volume, mute and foreground app. Close and cancellation terminate the connection and pairing attempts. | Typed negotiated capability and subscription operations. |
| Reconnect and wake | Reconnect uses the saved client identity and TV pin. Wake-on-LAN depends on the learned MAC and TV settings. | Existing identity storage and compiled wake operation. |
| Physical software | The baseline establishes Remote v2 as the protocol. It has no supported Android OS or firmware query. Discovery service data does not establish OS version. | Record protocol evidence independently. Preserve any explicitly supported device version fields only when their semantics are known. |
| Models and persistence | Generic Remote v2 profile; negotiated features control availability. Pairing credentials are keyed by saved device ID. | Preserve identity and credentials; only apply restrictive profiles with evidence. |

The current managed mappings cover navigation, media, volume keys and power. The binary engine remains necessary. See the [capability audit](../../provider-capability-audit.md).

The 1.1.0 source package requires `remote-v2.session`. The compiled binary framing, pairing, certificate proof, IME and audio state live in the driver runtime. The Android adapter still owns discovery and the typed TV controller. The TLS fixtures exercise approval, cancellation, certificate mismatch and credential reuse. The source package stays outside the publishing index pending full device parity validation.
