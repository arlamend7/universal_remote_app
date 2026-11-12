# Driver integrations

This folder is an independent project of declarative integration
definitions. Flutter never bundles these source files; the app only ships a
**signed seed** generated from a verified publication.

```text
drivers/
├── catalog.json                         # source index: integration folders + channel
├── providers/<provider>/<family>/        # one folder per compatibility family
│   ├── manifest.json                     # identity, engine, runtime, compatibility, profiles
│   ├── mappings.json                     # runtime operation → validated engine call
│   ├── capabilities.json                 # alternatives, conditions, probes, restrictions
│   ├── connection.json                   # engine connection data + runtime session policy
│   ├── discovery.json                    # how network evidence identifies the device
│   └── device.json                       # manual setup, connection policy, wake
├── fixtures/                             # test-only data, never published
│   ├── v2/                               # schema-drift fixtures shared by Python and Dart
│   └── example-json-websocket/           # sample integration for the json-websocket engine
├── schema/v2/                            # JSON Schemas (executed by the tools)
├── tools/{validate,package,sign,publish}/
└── tests/
```

| Integration | Folder | Channel |
|---|---|---|
| `lg.webos.22-plus` (webOS ≥ 7) | `providers/lg-webos/webos-22-plus` | stable |
| `lg.webos.legacy` (webOS < 7) | `providers/lg-webos/webos-legacy` | stable |
| `android.tv.remote-v2` | `providers/android-tv/remote-v2` | stable |
| `samsung.tizen.supported` | `providers/samsung-tizen/tizen-supported` | stable |
| `roku.ecp.supported` | `providers/roku-ecp/roku-supported` | development |

## Updating an integration

Edit the JSON in its folder. There is no version number to bump and no new
folder to create. `lastUpdatedAt` must **not** be written by hand: the
publisher stamps it whenever the folder's content changes, and reuses the
previous value (and the byte-identical package) when it does not.

```sh
sh drivers/tools/validate/validate.sh drivers/providers/lg-webos/webos-22-plus
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s drivers/tests
```

The validator compiles the folder with the same engines the app uses, so an
unknown operation, an unsafe URI or key, an unexecutable capability or a
manifest/capability mismatch is rejected before publication.

Create a new integration folder only for a genuinely different compatibility
family (different protocol behaviour or requirements), and add it to
`catalog.json`. Integration and provider IDs are permanent.

## Publishing

Merging to `main` publishes changed integrations through
`.github/workflows/publish-drivers.yml` (see `docs/drivers/publishing.md`).
Local dry run with a throwaway key:

```sh
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out /tmp/test.pem
python3 drivers/tools/publish/build_site.py --output /tmp/site --key /tmp/test.pem --key-id local
```

## Development builds

- `--dart-define=DRIVER_LOCAL_PATH=/absolute/path/to/drivers/providers` installs
  every integration folder below that path into separate development storage.
- `--dart-define=ALLOW_DEVELOPMENT_INTEGRATIONS=true` offers development-channel
  integrations (such as Roku ECP). Release builds ignore both flags.
