# Content-addressed installation

`remote_driver_manager/lib/src/installation` replaces version-numbered package
storage. Layout under the platform driver directory:

```text
installed-drivers/
├── objects/<sha256>/driver.zip    # exact verified bytes, never modified
├── objects/<sha256>/record.json   # provenance: catalog hash, revision, key, source, lastUpdatedAt
├── inventory.json                 # schema 2: one record per integration
├── catalog-cache.json             # exact signed v2 catalog envelope + ETag + checkedAt
├── updates.json                   # next automatic check
└── legacy-families.json           # enabled state of retired version-based families
```

## Inventory record

| Field | Meaning |
|---|---|
| `integrationId`, `providerId` | Stable identity |
| `current` | Active verified generation (SHA-256) |
| `previous` | Generation `current` replaced; rollback target |
| `staged` | Verified generation waiting until no session uses the integration |
| `rejected` | Generation the user rolled back from; never auto-reinstalled |
| `installedAt`, `updatedAt`, `lastUpdatedAt` | First install, last activation, publisher timestamp |
| `enabled` | User toggle |
| `assignments` | `deviceId → {profileId, assignedAt}` |

## Update check (`IntegrationUpdateService`)

The app refreshes the signed catalog when it opens or returns to the foreground.
If an installed driver has an eligible new package, Settings → Drivers shows
a download action. Tapping it installs the updates from that catalog. Updates
downloaded during a connection take effect after the session ends.

1. Refresh the signed catalog when the app opens; lower or conflicting
   revisions are rejected.
2. Check for eligible updates without downloading packages.
3. Match installed integrations by ID and compare the installed SHA-256 with the
   catalog SHA-256. Equal hashes download nothing.
4. Otherwise skip if rolled back, disabled, development-only, or the runtime cannot
   execute it; then download the immutable object, check size, SHA-256 and the
   package signature, decode it, require its manifest to match the signed entry,
   and run the runtime validator.
5. Write the object atomically (staging directory + rename), keep the previous
   generation, and activate it — or stage it while a session uses the
   integration. Assignments to profiles the new generation no longer has are
   cleared so those devices are resolved again.
6. Garbage-collect objects no record references as `current`, `previous` or `staged`.

`lastUpdatedAt` is display/diagnostics only and never decides an update.
If the active object is missing or corrupt, `load` falls back to the previous
verified generation.

## Migration from version-based storage

`LegacyDriverStorageMigration` removes `inventory.json` (schema 1),
`driver-<len>-<id>-<version>.json` files, the v1 catalog cache and its schedule,
keeping each family's enabled state and the next check time. The legacy files
cannot be re-verified as signed bytes, and their bindings could only repeat
compiled defaults, so no behaviour is lost by re-installing v2 objects.

`migrateLegacyDeviceMetadata` rewrites saved-device metadata: the
`managedDriver*` keys are dropped and, when exactly one published integration
`replaces` the old family, `driverIntegrationId` is set. Device IDs, endpoints,
credentials, certificate pins and dashboards are untouched; ambiguous families
(LG now has two integrations) are resolved again from software evidence.

The app switches from the version-based manager to this subsystem when the
generic controller lands (phases 5–6); until then both coexist.
