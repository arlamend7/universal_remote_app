# Device management and remote review

Implemented November 6, 2026. The theme, primary navigation and saved controller
layouts are retained. No dependencies were added.

## Action ownership

| Action | Primary location |
| --- | --- |
| Discover and add nearby devices | Devices → Find Nearby Devices modal |
| Manual address | Devices → Connect by IP |
| Power off / configured wake | Remote power button; optional custom grid controls |
| Rename, pairing, disconnect, forget, connection and capabilities | View details → Device settings |
| Theme, accent, feedback, diagnostics and help | Settings page |
| Per-TV controller layout | Customize remote; same editor from Device settings |

Three-dot menus contain no power or disconnect actions. Duplicate header Add and
sheet-footer Close actions were removed. Device settings and app preferences use
distinct titles. Capability presentation belongs to the device context.

## Discovery and identity

The Devices viewport no longer subscribes to discovery. Its dedicated modal owns
progress, errors, retry/cancel, new-device Add actions and an Already added section.
Add saves the device, closes the modal and opens its remote. Dismissal cancels the
search; late results are ignored and network resources are released. Reopening
waits for the previous cleanup.

`DeviceIdentity` compares permanent provider IDs, normalized UUID/USN/UDN aliases
and configured MACs. Endpoint fallback is limited to compatible manual profiles
without conflicting permanent identities. Names are never identity. Matching
permanent identities consolidate multiple interfaces/discovery mechanisms.

`DiscoveryProfiles` learns the stable identity of a matched manual profile so
later address changes do not create a new device. It retains the saved profile ID,
credentials, trust, name and layout. **Update address** explicitly changes hosts
while preserving scheme/port and certificate. Updating metadata replaces a saved
row in place rather than moving it to the bottom.

An old manual profile with no previously learned identifier cannot be reliably
matched after its address changes. The implementation does not guess from a name
or model, or merge conflicting UUIDs sharing a reused address.

## Power and connection feedback

The optional pure Dart `DeviceWakeProvider` contract declares integration-owned
offline wake. LG enables it with a valid configured MAC; metadata on an unrelated
provider does not enable wake. The remote sends the existing Wake-on-LAN request
directly, reports that it was sent, and does not assert that the TV has started.
Network wake must also be enabled on the physical TV.

Status distinguishes Disconnected, Connection lost, Unreachable, Connection error
and Power off requested. A lost socket does not establish physical power state.
Only an accepted power command marks intentional shutdown. That command releases
the session to prevent reconnecting to a TV just turned off.

The header's status button replaces the inline error and multiple offline-action
sections, with no empty row below the header. One explanatory sheet appears per failed/lost attempt without remote
wake. Configured wake does not automatically open an error sheet. Dismissal is
respected; feedback does not reopen it. Intentional disconnect and background
suspension do not generate notifications. Certificate review and editing close
the status sheet before handing off, so they cannot obscure pairing.

Power confirmation, app/input choices and keyboard entry retain their originating
session. Changing selection during a modal cannot apply its pending action to a
different TV. Grid shutdown buttons and local sleep share connection-owned shutdown.

## Stability

The remote shell observes selection and profile/layout changes. Classic modules
and grid items observe the feedback they consume; volume/content updates do not
reconstruct canvas geometry. Equal feedback readings are ignored. Unrelated commands
no longer request another volume reading. Duplicate active connection requests
reuse the target; endpoint/trust changes still permit a new session. Current-content
space remains reserved across offline transitions. The later phone-fitting update
keeps connection feedback within the header so an empty status region is unnecessary.

## Validation

- 51 package/architecture tests and 51 app tests passed: 102 total.
- Formatting, analysis, readability checks and dependency audit passed.
- macOS debug, Android ARM64 debug and iOS simulator debug builds passed.
- Rendered Flutter phone fixtures: `artifacts/design/implemented-v1/20-discovery-modal.png`
  and `21-offline-explanation.png`.

Tests cover identity matching, new-vs-registered results, cancellation/late results,
manual-profile identity learning, preservation of trust/order/layout, power/wake
availability, shutdown cleanup, notification frequency, background lifecycle and
changing selection during confirmation. Existing TLS, pairing and grid tests pass.
Physical TV behavior remains unverified.
