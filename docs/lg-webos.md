# LG webOS integration

## Verified protocol references

Protocol facts were checked against upstream [LG Connect SDK](https://github.com/ConnectSDK/Connect-SDK-Android-Core)
and the current [Home Assistant LG client endpoints](https://github.com/home-assistant-libs/aiowebostv/blob/main/aiowebostv/endpoints.py)
and [registration payload](https://github.com/home-assistant-libs/aiowebostv/blob/main/aiowebostv/handshake.py).
These are references for interoperability; their implementations were not copied.
The historical signed test identity is not embedded. Newer firmware may reject
older signed manifests or grant different permission sets. Registration success
alone does not establish that commands are authorized.

## Discovery and identity

IPv4 SSDP searches for `urn:lge-com:service:webos-second-screen:1`. Responses
must contain that exact service type and a UUID USN. Header names are normalized;
malformed and conflicting responses are ignored. Duplicate UUIDs collapse.
The sender's address becomes the connection endpoint. Advertised headers are
retained, including location and identifiers. Friendly name/model are used if
advertised; otherwise the UI shows LG webOS TV and model unknown. UPnP XML
metadata retrieval and multi-interface/IPv6 discovery are not implemented yet.
No untrusted LOCATION URL is fetched automatically.

Manual numeric-IP configuration is independent of multicast and uses a persisted
random profile ID. A manual profile is not falsely labeled a manufacturer UUID.

## Connection and pairing

TLS (`wss`, port 3001) is the default. Unknown self-signed certificates are rejected.
Connection details accept an out-of-band verified exact certificate as base64 DER.
Certificate acceptance is scoped to the configured endpoint and exact bytes;
there is no global TLS override. Legacy `ws` on port 3000 requires an explicit
choice. The separate legacy-navigation permission covers TVs that provide an
unencrypted pointer URL while the main socket uses TLS. There is no automatic
fallback or downgrade.

The app sends a prompt registration request with an unsigned versioned manifest
containing only permissions for its implemented control groups. It handles prompt
acknowledgement separately from the final registered event, waits up to 45 seconds,
then persists the authorized client key through an injected `CredentialStore`.
Saved keys are reused. Registration rejection with a saved key removes the stale
key and asks the user to pair again; it does not loop through prompts indefinitely.
Pairing can be retried, cancelled, or forgotten. A caller may supply a different
manifest to `LgDeviceController` for a verified firmware profile.

## Implemented SSAP operations

| Capability | Operations |
| --- | --- |
| Volume | `audio/getVolume`, `volumeUp`, `volumeDown`, `setVolume`, `setMute` |
| Applications | `com.webos.applicationManager/listApps`, `system.launcher/launch`, `com.webos.applicationManager/getForegroundAppInfo` |
| Inputs | `tv/getExternalInputList`, `tv/switchInput` |
| Navigation setup | `com.webos.service.networkinput/getPointerInputSocket` |
| Power-off | `system/turnOff` |

Volume parsing supports flat and nested `volumeStatus` responses, reads mute
state, and supports optional continuous subscriptions. Application IDs and input
IDs come from the television; no service-specific application IDs are hardcoded.
The package can query the foreground app; the initial remote UI does not display
it continuously. Input listing and switching are implemented; no speculative
current-input protocol operation is invented.

## Pointer socket

The pointer endpoint must refer to the same numeric host as the SSAP endpoint.
Navigation is enabled only after its separate socket opens. Direction/back/home
messages use a button name and terminate with a blank line. OK sends a click
message. This framing is independent of SSAP JSON and can be extended to move
and scroll records without changing the main request client.

## Failures and lifecycle

Requests have unique IDs, can run concurrently, and time out. Subscriptions have
bounded initial responses and send unsubscribe on cancellation. Socket loss,
malformed JSON, explicit close, and disposal fail pending work and close resources.
Unsupported/denied capabilities are downgraded with safe errors. Unexpected
socket loss triggers at most three consecutive reconnect attempts with backoff;
user disconnect, backgrounding, and disposal stop retries. Foreground resumption
reconnects a previously active session. It does not promise background operation.

## Power-on and compatibility limits

Wake-on-LAN sends a standard magic packet using a valid manual or learned MAC.
After a successful connection, the optional `DeviceWakeAddressSource` reads
LG connection-manager information and matches the session IP to a connected
Wi-Fi/Ethernet interface. When that interface reports a valid IPv4 subnet mask,
the app also saves its directed broadcast, avoiding unrelated default routes.
The unsigned prompt manifest requests only the added `READ_NETWORK_STATE` scope
for this operation. A denial leaves normal controls and pairing intact.

If the TV does not expose this information, macOS can try the system neighbor
table where access is permitted. The app does not guess a MAC or subnet from an
IP alone, and manual values always win. Enable network wake on the TV; some
models, network interfaces, routers, and power states cannot wake.
No physical television has been tested in this workspace. Review the hardware
checklist before claiming a model/firmware combination is supported.

## Session capability checks

Absolute volume, mute, and feedback are tracked separately from relative volume. An explicit command rejection disables the rejected control for that session. See the [provider capability audit](provider-capability-audit.md).
