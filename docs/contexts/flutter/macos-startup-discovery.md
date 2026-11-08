# macOS startup prompts and LG discovery fixes

## Reported behavior

The app requested the computer password repeatedly at launch, and Find TVs showed
only a generic interrupted message even though Local Network permission was enabled.

## Startup storage

Bootstrap previously used the secure-storage adapter for saved profiles, theme,
and diagnostics. Those three startup reads unnecessarily touched macOS Keychain.
The app now separates ordinary native preferences from protected credentials:

- UserDefaults on Apple platforms and application-private SharedPreferences on
  Android hold only saved-device metadata and UI settings.
- Dart and native channel implementations whitelist the three non-secret records.
  Pairing-key record names are rejected by this adapter.
- The secure credential store still reads/writes pairing keys through native
  protected storage. There is no plaintext fallback or Keychain permission bypass.
- Startup performs zero credential-store reads; credential access begins when the
  user connects/pairs, not while loading the initial screen.

Ad-hoc debug rebuilds can change the code identity macOS uses for protected access.
The app does not promise that actual pairing-key access can never require OS
approval. It no longer requests that approval just to render startup settings.
See [Apple local-network identity guidance](https://developer.apple.com/documentation/technotes/tn3179-understanding-local-network-privacy).

## Discovery

The previous search bound a single wildcard socket and relied on the system's
outgoing multicast route. Discovery now runs a bounded search for each active IPv4
address. IP_MULTICAST_IF is selected using the Dart SDK's portable raw socket
constants; Dart's multicastInterface property is unimplemented and is not used.
A failed interface no longer discards advertisements received on another interface.
UUID deduplication still combines duplicate responses.

A temporarily write-blocked UDP send retries on write readiness rather than
silently behaving as if the request had been sent. Sockets, timers, and listeners
still close on completion, timeout, and cancellation. The macOS release runner
now declares network.server as well as network.client, because UDP discovery binds
a socket; debug already declared both.

Discovery messages distinguish permission errors, unavailable routes and timeouts,
with safe OS error codes. Raw exception/protocol payloads are not displayed.
No system privacy preferences, Keychain ACLs, or user passwords were changed.

## Runtime evidence

A temporary Flutter diagnostic was run with this application's actual macOS runner,
sandbox, bundle identity and native channel registration. It used the normal
AppBootstrap followed by the full discovery controller/provider path:

```text
UNIVERSAL_PREFERENCES_PROBE startup_success=true
UNIVERSAL_DISCOVERY_PROBE devices=1 error=null
```

The updated application discovered one LG device. No registration, pairing,
credential read, or TV control command was issued. This verifies the discovery path,
not volume/navigation or firmware compatibility. The diagnostic process was quit;
the normal lib/main.dart application was rebuilt afterward.

## Regression coverage

- Startup and ordinary settings do not read protected credentials.
- Client keys are routed only to protected storage.
- Native preferences support read/write/delete but reject credential record names.
- Permission/route messages are actionable and omit raw exception details.
- A failed interface cannot discard another interface's result; duplicate UUIDs
  collapse; all-route failures remain distinguishable from a successful empty search.
- An actual local UDP responder verifies M-SEARCH framing, source-port replies,
  and parsing, without requiring a television.

No dependency was added. The resolved graph remains at 91 reviewed entries.
The existing unit/widget/security suites remain in place. The initial storage/discovery fix run
contained 51 passing tests (36 package/structure tests and 15 app tests).

## Updating the running app

Completely quit the old app and run again from the application directory:

```sh
/Users/karoline/Code/Dependencs/flutter/bin/flutter run -d macos -t lib/main.dart
```

Hot reload cannot install the native preferences channel or new entitlements.
After restarting, choose Find TVs, select the TV, and approve pairing on its screen.
The previous secure connection and certificate requirements remain unchanged.

## Visible search progress and connection-stage diagnostics

The discovery screen now has an explicit Searching for LG TVs status, an 8-pixel
progress bar, and a spinner in the disabled search button. Nearby-device empty
text also switches to a searching message. These indicators track the actual
busy state; no artificial minimum delay or fake percentage is introduced. A
search that fails before a frame is painted can transition directly to its error.
Two widget regressions hold discovery pending, verify the indicator remains
visible and repeated searches are disabled, then verify success/error cleanup.

The supplied remote-screen screenshot identified the TV as 172.16.1.13. A read-only
probe found both LG control ports (3000 and 3001) reachable. A normally validated
secure WebSocket attempt returned HandshakeException with
CERTIFICATE_VERIFY_FAILED. No certificate was auto-trusted, no pairing registration
was sent, and no TV command or credential was transmitted. This confirms a TLS
trust problem on the secure path, not missing PowerShell login credentials.

The app now distinguishes TLS/certificate rejection, network-access errors,
refused control ports, timeouts, rejected WebSocket upgrades, and native protected
credential-storage failures. Secure-storage errors no longer become misleading
network errors, and their native payloads/client keys are never displayed.
Code 65 wording explicitly allows both OS blocking and an unreachable route,
rather than implying that routing is its only possible cause.

The advanced manual secure route accepts a separately verified TV certificate
configured in Connection details; the in-app review flow is described below. The user may instead explicitly choose Legacy connection
on a trusted local network where compatible. The app never makes that security
choice automatically. XML/plist files declare native permissions; the LG client
key comes from on-TV pairing approval and remains in protected storage.

The loading/error-stage verification passed 58 tests before the in-app
certificate-review flow below was added.

Protected-key reads now happen only after the control connection and its normal
TLS validation succeed. An unreachable TV or rejected certificate therefore
cannot trigger an unnecessary Keychain read. A regression verifies zero credential
reads when the handshake fails. Explicit legacy mode continues to require the
user's opt-in; this ordering does not introduce automatic fallback.


## In-app certificate review and encrypted pairing

The offline LG remote now offers **Review TV certificate and pair**. It reads the
certificate with an isolated TLS handshake that always rejects the untrusted
certificate, sends no application data, and closes without pairing. The review
displays the TV IP address, certificate subject and SHA-1 comparison fingerprint.
The SHA-1 value is display evidence only: transport trust compares the complete
DER certificate bytes, scoped to the configured endpoint.

The user must confirm the TV address in its network settings and explicitly
choose **Trust and pair**. This is first-use trust, not independently proven TV
identity; the dialog explains that and recommends comparison through a trusted
source. Advanced out-of-band certificate provisioning is still available.
A previously stored certificate is never silently replaced: changed evidence
gets a distinct warning and a separate replacement confirmation. Cancelling
leaves existing trust and protected credentials unchanged.

After approval, the app persists the exact certificate on the existing device
profile and retries encrypted pairing. It still waits for approval on the TV
before storing a client key or enabling typed capability controls. No global TLS
override or automatic unencrypted fallback is installed. Certificate inspection
is injected through AppDependencies and stays in the pure Dart network package;
widgets do not issue protocol commands.

Verification: 61 tests pass (40 protocol/structure and 21 app tests). The new
application tests exercise cancellation, changed-certificate cancellation and
the actual LG driver from certificate consent through simulated TV approval,
protected key persistence, pointer clicks and volume commands. The local TLS
server regression verifies inspection does not grant trust and that only the
approved exact DER pin enables the subsequent secure connection.

A fresh read-only check against 172.16.1.13 during this change timed out on port
3001; the earlier certificate rejection remains historical evidence, not a
claim of current TV connectivity. Port 3000 also closed before completing its
WebSocket upgrade. No live pairing or TV control command was sent. Real-TV
operation still requires the TV to be on/reachable and the user to complete its
pairing prompt.

## Volume controls and optional feedback

A disabled volume panel was traced to an overly strict capability check: it
required volume and mute to arrive in the same `audio/getVolume` response.
LG's protocol exposes independent volume and mute queries. `LgVolumeReader`
now accepts flat or nested volume levels, preserves top-level mute alongside
nested volume, and queries `audio/getMute` when mute feedback is absent.
Unknown mute is represented explicitly instead of inventing an unmuted state.

Status queries no longer revoke write capabilities. If volume feedback fails,
the driver exposes volume as known, not verified: Lower/Louder can be attempted,
while the slider waits for an actual reported level. A rejected adjustment
command still revokes the control and surfaces the safe error. Mute toggling
requires a known mute state. The volume card explains unavailable feedback or
controls rather than silently leaving them grey. No volume-changing probe is
sent during connection.

Regressions cover separate/nested feedback, missing mute permission, subscription
updates, denied writes and a complete app session with denied volume reads but
working adjustment commands. These are simulated protocol tests; actual TV
volume behavior remains unverified until exercised on hardware.
