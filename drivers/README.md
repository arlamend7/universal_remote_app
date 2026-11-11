# Driver authoring

Driver source directories are inputs to the authoring tools. Flutter does not bundle them as assets. The checked-in example targets a fictional TV and is suitable for local tests.

1. Create a provider directory with `manifest.json`, `discovery.json`, and `capabilities.json`.
2. Put each referenced command in `commands/<id>.json`. Persistent exchange definitions can live in `workflows/<id>.json`.
3. Declare compatibility profiles in the manifest, using exact known models and firmware evidence. Keep platform firmware versions separate from the driver release version.
4. Validate using the workspace Dart SDK. The validator runs the same typed decoders used by the runtime. The JSON schemas describe the file formats. The catalog schema describes the planned signed distribution index.

```sh
sh drivers/tools/validate/validate.sh drivers/providers/example-tv
python3 drivers/tools/package/build.py drivers/providers/example-tv /tmp/example-tv.zip
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s drivers/tests
```

The tool enables filesystem loading explicitly. The packaged ZIP is unsigned and intended for development. Signing and distribution are separate phases. The production app has no filesystem driver-source configuration.

To load a source directory directly in a development app, run Flutter with
`--dart-define=DRIVER_LOCAL_PATH=/absolute/path/to/driver`. Use a new driver
version for changed files. Development installs use separate local storage.
Roku also requires `--dart-define=ENABLE_ROKU_ECP=true`. Release builds ignore
both development flags. The compiled bindings format uses `bindings.json`
and the `compiled.bindings` operation. Each compiled adapter validates its
permitted wire values.
