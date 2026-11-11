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
