# Protocol boundaries

| Concept | Meaning | LG example |
| --- | --- | --- |
| Device discovery | Find a candidate endpoint and identity | SSDP service advertisement |
| Capability discovery | Determine which control groups are available | Read queries and pointer-socket probe |
| Command discovery | Learn individual supported operations/parameters | Driver knowledge, then actual operation results |
| Pairing | User grants authorization to a controller | On-TV prompt and client key |
| Transport | Move bytes/messages | WebSocket and UDP |
| Application protocol | Interpret and correlate messages | SSAP JSON and pointer input text |

An advertised category does not imply a capability, and an open socket does not
imply authorization. Driver knowledge is evidence, not a guarantee for every
firmware. Learned commands and user profiles should preserve provenance.

Future drivers may use HTTP/HTTPS, TCP, BLE, classic Bluetooth, MQTT, native IR,
RF hubs, Matter, gateways, or cloud APIs. They should adapt those transports to
small capability controllers, keeping transport framing outside core. HTTP work
should reuse a verified compatible DEVCOM flutter_client_factory version rather
than create competing application HTTP infrastructure. Envx and its adapters
remain optional until layered configuration is actually needed.

| Technology | Discovery/control considerations | Hardware or service needs |
| --- | --- | --- |
| Infrared | Line of sight; often one-way with no verified state | Native emitter or external hub; learning receiver for learning |
| RF | Frequency/protocol-specific; rolling codes may prevent replay | Compatible certified RF bridge |
| BLE/classic Bluetooth | OS permissions, discovery, pairing, service profiles | Compatible radio and documented device protocol |
| Matter | Fabric commissioning, attestation, IP transport | Matter controller stack; border router for Thread |
| MQTT | Topic/discovery conventions differ by ecosystem | Reachable authorized broker |
| Zigbee/Z-Wave | Coordinator-specific gateway protocols | Authorized coordinator/gateway |
| Cloud APIs | Account credentials, availability and rate limits | Manufacturer-supported cloud integration |
| HDMI-CEC | Platform access is limited on phones | External host or bridge with CEC access |

None of these future transports is implemented by the LG-first release. A socket
adapter by itself does not make an undocumented device controllable.
