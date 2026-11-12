# Security and platform integration

## Credentials and preferences

`SecureCredentialStore` adapts the pure Dart contract to `flutter_secure_storage`
11.2.0. The plugin uses native protected storage (Apple Keychain and Android
Keystore-backed encrypted storage). Pairing keys have independent per-device keys;
profile JSON never contains client keys. There is no plaintext credential
fallback. Storage failures are shown and must be resolved.

Pairing credentials remain in protected storage. Ordinary settings and TV profile
metadata now use `NativePreferencesStorage`, backed by UserDefaults on Apple
platforms and application-private SharedPreferences on Android. Both the Dart and
native adapters restrict writes to the three non-secret preference records;
client-key entries are rejected. Profiles never contain a pairing key.

Startup reads only these ordinary preferences. It does not query Keychain merely
to render Devices or Settings.

On iOS, credentials use first-unlock-this-device accessibility and the runner has
a Keychain entitlement. macOS retains native non-data-protection Keychain for actual
pairing-key access, avoiding shared-access provisioning for local development.
After a successful Keychain read, macOS reuses the key in memory for the current
app session and skips writes of the same value. Forget/Re-pair evicts the cached
key, and app disposal clears the cache. Denied reads are never cached. Nothing
about this reuse changes at-rest protection or the app's Keychain permissions.

macOS may still request authorization for a protected key, particularly after an
ad-hoc debug rebuild changes code identity. The application does not suppress or
bypass that security control. Android backup remains disabled for protected data.
Real-device credential invalidation and persistence remain hardware tests.

To reduce approvals across macOS rebuilds, use a consistent Apple Development
signing identity and bundle ID in Xcode instead of **Sign to Run Locally**. A
distributed build should use its stable release signing identity. A switch to
the data-protection Keychain requires proper provisioning and an explicit
migration of existing items; flipping the option alone can make old keys
unavailable. See [Apple's code-signing requirements](https://developer.apple.com/documentation/technotes/tn3127-inside-code-signing-requirements)
and the [plugin's macOS provisioning notes](https://pub.dev/packages/flutter_secure_storage/versions/11.2.0#macos--ios).

## TLS and local transport

Normal TLS uses SDK certificate validation. An explicitly configured certificate
pin uses an empty trust store and an exact DER certificate comparison scoped to
this host/port. This prevents an otherwise system-trusted replacement certificate
from silently bypassing the pin. No trust-all callback or global HttpOverrides
is installed. Test coverage includes default rejection, wrong-pin rejection, and
exact-pin acceptance with a temporary local TLS server.

The offline LG remote offers **Review TV certificate and pair**. Inspection uses
an isolated TLS handshake whose certificate callback always returns false. It
collects evidence without granting trust, sending application data or reading
pairing credentials. The user sees the address, subject and SHA-1 comparison
fingerprint and must explicitly approve first-use trust. Address and certificate
evidence alone do not authenticate the TV: verify the address on the TV, use a
trusted network, and compare the certificate through a trusted source where
available. The dialog states this limitation. SHA-1 is display evidence only;
acceptance matches every byte of the full DER certificate.

Approval stores that exact pin on the same non-secret TV profile and retries
TLS pairing. The TV must separately authorize pairing before controls enable.
Changed certificates trigger a distinct replacement warning and require another
explicit confirmation; cancelling preserves the previous pin. No certificate is
silently installed or replaced. Advanced manual provisioning of an independently
verified base64 DER certificate remains available in Connection details.

Legacy connections and legacy pointer sockets require explicit permission. The
Android manifest permits cleartext for these user-selected local numeric-IP
connections; application code enforces opt-in and never automatically downgrades.
Legacy pairing sends authorization over an unencrypted LAN connection; use only a
trusted network. Apple local networking is declared. No inbound control server,
cloud account, backend, analytics, or internet-exposed endpoint is created.

## Discovery permissions

Android declares Internet, Wi-Fi state, and multicast-state permissions. A small
application-owned method channel acquires/releases WifiManager.MulticastLock and
releases it on stop. SSDP cancellation also closes the UDP socket.

Both macOS debug and release sandbox configurations allow UDP binding through
the network.server entitlement, alongside outgoing connections. No persistent
control server is created. Local-network user consent remains required. See
[Apple local-network privacy guidance](https://developer.apple.com/documentation/technotes/tn3179-understanding-local-network-privacy).

iOS declares NSLocalNetworkUsageDescription and local-network ATS allowance.
Runner.entitlements requests com.apple.developer.networking.multicast. Physical
device signing requires an Apple-approved multicast entitlement and a provisioning
profile that includes it. This cannot be granted by source code. Without it,
multicast discovery may be unavailable; manual IP connection remains independent.

Preparation reads the Wi-Fi or Ethernet connection state. Showing the exact
Wi-Fi name is optional and may require foreground location permission from the
operating system. The app reads the SSID for display only. iOS device builds
must enable Access Wi-Fi Information for the App ID and use a provisioning
profile that includes `com.apple.developer.networking.wifi-info`.
Simulator compilation does not certify physical-device network behavior.

## Logging and input limits

DiagnosticLogger accepts application event codes and controlled error codes only.
It never receives raw protocol messages, authentication payloads, client keys,
pointer URLs, or free-form exception text. It supports enable/disable and minimum
levels. SSAP errors are translated to safe messages. Settings never display keys.
Frames are limited to 2 MiB at the WebSocket decoder. SSDP parsing rejects malformed
or conflicting headers. Discovery does not fetch advertised LOCATION URLs. IPv4 discovery binds to each
active address and explicitly selects IP_MULTICAST_IF via the SDK's portable raw
socket option constants. It does not use Dart's unimplemented multicastInterface
property. Failures on one interface do not discard results on another. Write-blocked
sends retry on socket write readiness; initial-response windows remain bounded.
Socket permission and route errors are shown as distinct, safe messages with OS
error codes instead of a generic interrupted message.
Pairing does not bypass the TV's consent or authorization model.

## CI and dependencies

The user explicitly approved secure-storage and testing dependencies; Riverpod
was subsequently removed at the user's request. The verified web-free DEVCOM
route_definer 4.0.0 revision is now used and pinned, with source checks in CI. See dependencies.md for every
resolved package and source. CI checks the complete reviewed graph and rejects
drift. CI builds debug artifacts only; it has read-only repository permissions
and no publishing/release step. It is configured but has not run on GitHub because
this local workspace has no configured Git remote.
