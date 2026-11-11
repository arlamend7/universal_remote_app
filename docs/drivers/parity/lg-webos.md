# LG webOS parity audit

Baseline `f259d52`. The [TV API matrix](tv-api.md) lists all existing capability methods and their target operations.

| Area | Existing behavior to preserve | Target |
| --- | --- | --- |
| Discovery and identity | SSDP second-screen service and local probes. Profile IDs survive address changes and are separate from endpoints. | Declarative discovery plus the existing LG identity check. |
| Session and authorization | SSAP WebSocket, registration manifest, TV approval and saved client key. Secure endpoint is the default. Explicit legacy transport settings remain scoped to the saved device. | Persistent SSAP engine with authenticated request and subscription operations. |
| Certificate | Exact DER pin when configured. Existing certificate review and endpoint checks remain in force for the main and pointer connections. | Shared transport policy with LG-specific registration and pointer handling. |
| Feedback and errors | Request IDs correlate replies. Explicit permission and unsupported errors affect the relevant capability. A failed volume read leaves relative volume available. | Typed results and per-operation evidence. |
| Reconnect and wake | Bounded reconnect after loss. Wake-on-LAN uses the configured or learned MAC and broadcast address. | Retain reconnect generation and cancellation rules, and use the compiled wake operation. |
| Physical software | Post-authorization `com.webos.service.update/getCurrentSWInformation` reads `model_name` and saves `product_name` or `version` under the historical display field. | Preserve the reported fields, manufacturer software version and source. OS and firmware remain unknown unless the response establishes them. |
| Models and persistence | Generic webOS profile; individual features depend on responses. Existing client key and profile ID remain associated. | Use verified model evidence for restrictive profiles and retain the generic bootstrap profile. |

The present managed bindings cover volume, mute and power paths only. SSAP registration, pointer, launcher, subscriptions and IME still run in compiled code. Fixture coverage is recorded in the [capability audit](../../provider-capability-audit.md).
