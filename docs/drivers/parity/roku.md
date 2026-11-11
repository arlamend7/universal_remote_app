# Roku ECP parity audit

Baseline `f259d52`. The [TV API matrix](tv-api.md) lists all existing capability methods and their target operations.

| Area | Existing behavior to preserve | Target |
| --- | --- | --- |
| Discovery and identity | Roku ECP SSDP, local IPv4 endpoint validation and serial confirmation from device info. | Declarative discovery plus typed ECP identity checks. |
| Transport and permissions | Local ECP HTTP, serial checks and TV-side network control permission. This path does not use TLS or pairing credentials. | Retain the existing explicit ECP transport policy and permission errors. |
| Commands and feedback | ECP keypress and launch, app catalog, active-app lookup, optional tuner and media reads. Unsupported and permission errors revoke the relevant session capability. | Typed XML queries, validated key operations and read-based evidence. |
| Reconnect and wake | New session checks device info and serial again. PowerOn is only attempted for eligible TVs; physical wake remains unverified. | Preserve checks and report outcomes without claiming standby compatibility. |
| Physical software | `query/device-info` reads `software-version` and model fields. | Preserve raw reported values and identify them as manufacturer software, not firmware or Android-style OS numbers. |
| Models and release | Tuner and audio permissions depend on device flags and TV/player category. Existing development gate and publisher exclusion. | Preserve both release guards and serial-based identity. |

Managed bindings currently cover volume and power keys. See the [capability audit](../../provider-capability-audit.md).
