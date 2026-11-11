# Driver implementation and migration plan

The feature branch is `feature/dynamic-driver-runtime`. Validate each phase and publish its own Conventional Commit before starting dependent work.

| Phase | Change and validation |
| --- | --- |
| 0 | Record current dependencies, provider behavior and regression baseline. |
| 1 | Add typed driver metadata and operation contracts to core. Test decoding and rejection of malformed input. |
| 2 | Prepare reusable network sessions and identity evidence. Run network, discovery and certificate regressions. |
| 3 | Execute bounded declarative commands against a fictional local TV fixture. |
| 4 | Add approved pairing, response, subscription and reconnect workflows. Test cancellation, timeouts and scoped credentials. |
| 5 | Resolve driver versions and compatibility profiles in the manager. Test unknown and ambiguous device evidence. |
| 6 | Add independent schemas, authoring tools and a local fictional driver. Test development loading and builds without source definitions. |
| 7 | Implement local inventory, staged installation, activation and rollback. Test offline startup and interrupted installation. |
| 8 | Verify signed catalogs and packages, cache conditional requests and deduplicate downloads. Test with a local HTTP server. |
| 9 | Integrate Nearby and manual IP. Test local-first connection, on-demand installation and offline fallback. |
| 10 | Persist daily update eligibility and backoff. Test using an injected clock and preserve active sessions. |
| 11 | Add read-only Driver Explorer. Verify that browsing uses catalog metadata alone. |
| 12 | Validate, sign and publish artifacts independently to GitHub Pages. Verify release paths and signatures. |
| 13 | Migrate LG webOS with equivalent fixtures for SSAP, pointer, pairing, capabilities and wake. |
| 14 | Migrate Android TV, retaining trusted Remote v2 framing and TLS engines. |
| 15 | Migrate Samsung Tizen, preserving certificate and token checks and model-dependent capabilities. |
| 16 | Migrate Roku with the development-only distribution gate. |
| 17 | Remove only redundant registration and code after equivalence tests pass. Preserve persisted IDs and necessary compiled adapters. |
| 18 | Run full validation and document development, publishing, offline use and hardware checks. |

Before migration, compare each provider with the same fixtures on both paths. Keep the old controller or a compatible compiled adapter until the relevant behavior is covered. Record physical-device testing separately from fixture results.

## Capability parity follow-up

The follow-up migration starts from `f259d52`. Use the [TV API parity matrix](parity/tv-api.md) and the provider audits as the baseline before changing ownership of compiled behavior. [Device software resolution](device-version-resolution.md) defines the evidence boundary for compatibility checks.

### Follow-up status

| Phase | Outcome |
| --- | --- |
| 9 | Shared SSAP runtime, expanded LG source package and authenticated LG profile checks. The LG adapter still owns pointer, wake, discovery and device capability logic. |
| 10 | Shared binary Remote v2 runtime with pinned TLS and pairing fixtures. Android still uses its compiled typed adapter for control and discovery. |
| 11 | Shared Samsung channel, token and transport code with authorization and reconnect fixtures. Samsung still uses its compiled typed adapter. |
| 12 | Shared bounded Roku ECP client with the development-only gate. Roku still uses its compiled typed adapter for identity and capabilities. |
| 13 | Concurrent local releases, exact bundle resolution, per-TV compatible pins, and rollback of the default. |
| 14 | Removed the four provider packages. Their required adapter implementations and tests now live in the shared runtime. |
| 15 | Device Details shows reported TV software, the selected driver and profile, and whether information came from this connection or storage. |
| 16 | Offline restart, per-model update, rollback, and authenticated release handoff exercised by fixtures. |
| 17 | Automated results and physical-TV checks are tracked separately in [validation](validation.md). |

No physical hardware results are recorded for this follow-up. The candidate source bundles are available for development. Production distribution continues to use the checked-in publishing index.
