# Publishing integrations (GitHub Pages)

`drivers/tools/publish/build_site.py` builds the public static site:

```text
v2/catalog.json                          # signed envelope {keyId, payload, signature}
packages/objects/<sha256>/driver.zip     # immutable, hash-addressed packages
catalog.json + packages/<id>/<ver>/...   # frozen v1 index carried forward for old builds
```

## Steps performed

1. Validate every folder in `drivers/catalog.json` with the compiled engines
   (`validate.sh`) and the JSON Schemas; reject hand-written `lastUpdatedAt`
   or `version` fields.
2. Compute a source digest that ignores `lastUpdatedAt`. Unchanged → reuse the
   previous `lastUpdatedAt`, rebuild deterministically and require the same
   SHA-256 (and reuse its signature). Changed → stamp the publication time.
3. Build the deterministic, uncompressed ZIP; compute SHA-256 and size; sign it.
4. Generate the catalog payload (identity, channel, `lastUpdatedAt`, runtime,
   compatibility, profiles, capabilities and conditional capabilities,
   discovery and device rules, priority, `replaces`, object path, hash, size,
   signature, source digest) and validate it against `catalog.schema.json`.
5. Revision: unchanged content keeps the exact previous envelope; changed
   content requires a revision greater than the published one (auto-increment
   by default, explicit `--revision` must be higher).
6. Verify the previously published catalog with the same key before replacing
   it (a different key is refused).
7. Carry forward every object the previous catalog referenced, and the frozen
   v1 catalog and its packages, because a Pages deployment replaces the whole
   site.
8. Re-verify the output: catalog signature, schema, every object's hash, size
   and signature. Write a JSON publication report.

## Workflow

`.github/workflows/publish-drivers.yml`:

- **validate** (pull requests, `main`, feature branch): Python tests (which run
  the runtime validator for every integration), then a full site build and a
  seed extraction with an ephemeral key.
- **publish** (`main` push touching `drivers/**`, or manual dispatch): builds
  against the live site (`--previous` = Pages URL) with the
  `DRIVER_SIGNING_KEY_PEM` secret and `DRIVER_SIGNING_KEY_ID` variable, skips
  deployment when nothing changed, deploys, then verifies the live catalog,
  objects and signatures over HTTPS until the deployed revision matches.

The private key is never stored in the repository; public hosting is not
confidential.

## Seed

`drivers/tools/publish/refresh_seed.py --site <url> --public-key <pem> --output
apps/universal_remote_app/assets/driver-seed` copies the verified catalog and
stable packages into the app. On first run the app installs missing
integrations from the seed through the same verification as downloads; it
never overrides an installed generation or a newer cached catalog.

## Client configuration

- `DRIVER_TRUSTED_KEYS`: JSON map of key ID → Base64 uncompressed P-256 point.
- `DRIVER_CATALOG_BASE_URL`: the Pages base URL ending in `/`.
