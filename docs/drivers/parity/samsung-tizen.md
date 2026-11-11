# Samsung Tizen parity audit

Baseline `f259d52`. The [TV API matrix](tv-api.md) lists all existing capability methods and their target operations.

| Area | Existing behavior to preserve | Target |
| --- | --- | --- |
| Discovery and identity | Samsung MultiScreen SSDP service and local IP probes. Saved IDs and certificate evidence are independent of address. | Declarative service rules with existing discovery and identity validation. |
| Session and authorization | Secure remote WebSocket on 8002, TV approval, saved token and exact certificate pin. | Persistent Samsung protocol engine and scoped credential operations. |
| Responses and errors | Remote channel authorization events and optional installed-app list. App launch waits for transport write; it does not establish launch success on the TV. | Typed outcomes distinguishing local write and device acknowledgment. |
| Reconnect and wake | Reconnect reuses the saved token and certificate. Wake-on-LAN uses the configured or learned MAC. | Existing authorization and wake operations. |
| Physical software | Baseline discovery retains model evidence where provided. The controller has no supported firmware or Tizen version query. | Keep version fields unknown unless an identified response defines them. |
| Models and persistence | Generic secure remote profile. Apps and individual keys vary by TV. Existing token and pin remain attached to their profile. | Keep session evidence and reject restrictive profiles with missing version evidence. |

The managed bindings cover selected navigation, channel, volume and power keys. The compiled WebSocket authorization and app engine remain necessary. See the [capability audit](../../provider-capability-audit.md).
