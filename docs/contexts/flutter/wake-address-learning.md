# Automatic wake address learning

Turn the TV on manually, connect, then check **View details → Network wake**.
If it says **Address detected automatically**, the learned address is saved for
future launches. Enable network wake on the TV and test again from standby.

The app first asks the authenticated TV for its network details. The LG adapter
matches the session IP to a connected interface, validates the MAC, and computes
the subnet broadcast when a valid mask is present. It can use the older status
method name only if the newer method is unsupported, not after a permission
denial. The lookup is bounded and does not affect other controls.

macOS can fall back to an exact IPv4 neighbor-table lookup where permitted.
There is no subnet scan, privilege change, or attempt to bypass macOS 27 access
restrictions. Mobile targets can use the TV's report and retain manual entry.
Existing explicit MAC and broadcast settings are preserved, as are device
identity, credentials, trust and layout. Late results cannot recreate a
forgotten device or update a different session.

For the observed Mac network, the TV's `172.16.1.13` route and subnet broadcast
`172.16.1.255` use `en0`, while the limited broadcast `255.255.255.255` uses a
tunnel. If automatic detection is unavailable and the TV is still on that
subnet, the directed address is the manual broadcast value to try.

Older pairing approvals may require **Re-pair** for `READ_NETWORK_STATE`.
An unavailable lookup does not prove lack of wake support. A successful send
does not prove the TV woke.

Validation: 56 package/architecture tests and 69 app tests passed, along with
formatting, analysis, structure, dependency audit, macOS and Android debug
builds, and the iOS simulator build. The actual TV's firmware and standby
behavior still require hardware verification.
