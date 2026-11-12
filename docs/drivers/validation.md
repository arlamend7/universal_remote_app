# Validation record — dynamic integration migration

Branch `feature/dynamic-driver-runtime`, Flutter 3.47.5 / Dart 3.13.4, macOS
host, 2026-11-11. All results below are automated (fixtures, loopback servers,
recorded goldens). **No physical TV was available**; see
`docs/hardware-checklist.md`.

## Commands and results (final, after Phase 13)

| Check | Result |
|---|---|
| `flutter pub get --enforce-lockfile` | pass |
| `dart format --set-exit-if-changed packages apps/universal_remote_app/{lib,test} test tool` | pass (0 changed) |
| `dart run tool/check_structure.dart` (incl. provider-ID rule) | pass |
| `dart analyze --fatal-infos` | no issues |
| `dart run tool/audit_dependencies.dart` | pass, no new dependencies |
| `dart test test packages/{remote_core,remote_network,remote_driver_runtime,remote_driver_manager}/test` | 140 passed |
| `python3 -m unittest discover -s drivers/tests` | 16 passed (runtime validation of every integration, schemas, publisher, seed) |
| `flutter test` (app) | 132 passed |
| `flutter clean` then `flutter build apk --debug` | built |
| `flutter build apk --release` | built (57.6 MB) |
| `flutter build ios --simulator --debug` | built |
| `flutter build macos --debug` | built |

Baseline before the migration: 132 Dart, 5 Python, 133 Flutter tests.

## Parity evidence

| Provider | Generic transcript vs legacy golden | Declared differences |
|---|---|---|
| LG webOS (standard, `lg.webos.legacy`) | identical frames, results, errors, evidence | session `operatingSystemVersion` now parsed (`5.0`) |
| LG webOS (conditional, `lg.webos.22-plus`) | identical | session `operatingSystemVersion` `7.0` |
| Android TV | identical | none |
| Samsung Tizen | identical | none |
| Roku ECP | identical (incl. device category) | none |
| Discovery and manual setup (all four) | identical to recorded legacy outputs | none |

A mutation check (changing one Samsung key in JSON) makes the parity test fail,
so the comparison is not vacuous.

## Migration, offline, update and rollback

- Version-based storage migration: removes v1 files, keeps family enabled
  state and schedule; saved-device `managedDriver*` keys rewritten without
  touching IDs, credentials, pins or dashboards (`content_addressed_installation_test.dart`).
- Python → Dart round trip (`publication_roundtrip_test.dart`): publish →
  signed seed → offline install (no network requests) → provider registered →
  JSON edit republished as a new generation → hash update → planner uses the
  new mapping → rollback restores the seeded generation.
- Equal hashes never download; 24-hour schedule; staged updates while a
  session is active; corrupt objects fall back to the previous generation;
  catalog rollback and foreign signing keys are refused.

## Security review (diff-focused)

- JSON never executes code: mappings compile into closed engine vocabularies
  (allow-listed SSAP URIs, KeyEvent 0–319, `KEY_*`, documented ECP keys,
  bounded templates with named arguments, reserved envelope fields).
- Packages: size, SHA-256 and P-256 signature are checked before parsing; the
  manifest must match the signed entry; stored objects are re-hashed and size
  bounded on load; the ZIP reader accepts only listed file names.
- Unencrypted SSAP requires both the integration's `allowLegacyTransport` and
  the user's per-device opt-in; certificate pins and Remote v2 fingerprints are
  unchanged; no global TLS bypass was added.
- Development integrations and local folder installs are disabled in release
  builds. No credentials are logged.

## Not done / remaining

- Physical-TV verification for every provider and for the LG family split.
## Publication (2026-11-12)

- GitHub Pages publish run `43140753709` (attempt 2) built, signed, deployed
  and re-verified the live site: `v2/catalog.json` revision 1, key ID
  `universal-remote-1`, six integrations (four stable, two development).
- The app seed was generated from the live site and independently verified
  with the production public key (catalog signature, package SHA-256 and
  package signatures): `lg.webos.22-plus`, `lg.webos.legacy`,
  `android.tv.remote-v2`, `samsung.tizen.supported`. Development-channel
  integrations are excluded. `bundled_seed_test.dart` installs the bundled
  seed offline through full verification; the debug APK contains it.
- The private signing key is kept outside git (`.secrets/`, ignored) and in
  the `github-pages` environment secret.
