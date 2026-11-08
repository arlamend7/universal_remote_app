# Roadmap

## Before a hardware-validated release

Validate the complete LG flow using hardware-checklist.md, approve iOS multicast
provisioning, verify native credential persistence and invalidation, test TLS pins
and modern/legacy firmware, and run the configured CI on an actual repository.
Expand tests for sustained network transitions and concurrent lifecycle operations.
Improve interface selection for SSDP and optional bounded UPnP metadata retrieval
through the DEVCOM HTTP factory. Current discovery preserves advertised headers
and does not fetch descriptions. Add accessibility/device-size coverage and an
independent current-input adapter only after verifying an operation for it.

## Later integrations

| Integration | Likely transport | Dependencies/limits to investigate |
| --- | --- | --- |
| Samsung Tizen | Authorized WebSocket/HTTP | Model-dependent pairing and keys |
| Roku | Authorized control route to be confirmed | See [Roku feasibility](roku-feasibility.md) |
| Apple TV | Documented or supported authorized adapter | Pairing, protocol access and licensing |
| Smart ACs | Manufacturer LAN/cloud APIs | Model-specific protocols, accounts where needed |
| Traditional ACs and IR devices | Native IR or hub | Correct stateful IR encoding and compatible hardware |
| RF devices | Gateway | Frequencies, certification and rolling codes |
| BLE | DEVCOM universal_ble_server if compatible | Its dependency graph and device-specific GATT protocols |
| Matter | Controller/native stack | Commissioning, credentials, Thread border router |
| MQTT/Home Assistant | Authorized broker/API | Credentials and discovery conventions |
| Zigbee/Z-Wave | Coordinator gateway | Gateway hardware and protocol contracts |
| HDMI-CEC | Bridge | Host/hardware access unavailable on normal phones |

Do not add empty manufacturer packages. Extract reusable discovery, secure storage,
IR encoding/learning, or protocol modules only when the boundaries are stable and
independently useful. Verify package-name availability before publication planning.
User-configurable layouts, macros, and automation scenes are future application
features and must honor capability evidence and user authorization.
