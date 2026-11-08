# Resolved dependency inventory

The active dependency choices are Flutter SDK primitives for state, the explicitly
authorized secure-storage/test stack, and DEVCOM route_definer for navigation.
Riverpod remains absent. The original DEVCOM-only policy is retained as historical
input; its secure-storage/testing exceptions were explicitly authorized by the user.

The user supplied a web-free route_definer update. The local 4.0.0 manifest and the
pushed Git HEAD were verified at the same revision:
`7546848c78ab81a208655ad7083f608942309b63`. The app pins that immutable revision,
with no machine-local path dependency. Its runtime graph is Flutter and meta only;
it adds no direct web requirement. Pub.dev reported the older 3.2.0 manifest at the
time of verification. A hosted dependency can replace the pin after an updated
release is published and independently reviewed.

There are **91 resolved entries**. Versions/hashes are locked in pubspec.lock;
dependency-graph.json records every edge. The audit compares this full graph and
verifies the exact Git revision. The root explicitly declares its three local
packages as development dependencies because the smoke tools import them. No
additional analyzer/lint package was introduced; the structure check is SDK-only.

All entries below identify distribution source, not a claim that every hosted
package is owned by DEVCOM. Secure-storage/test transitives are permitted by the
user's revised authorization. The web package is still present through that
pre-existing stack; route_definer 4.0.0 does not require it. Application WebSocket
and UDP code uses dart:io; test infrastructure may resolve HTTP/WebSocket helpers.

Flutter 3.47.5 / Dart 3.13.4. Dependency manifests, APIs used by this project, and
SDK constraints were checked through source inspection and actual resolution.
Upstream development dependencies do not propagate into this workspace.

| Package | Version | Publisher or distribution source | Direct resolved dependencies |
| --- | --- | --- | --- |
| `_fe_analyzer_shared` | 103.0.0 | [pub.dev/_fe_analyzer_shared](https://pub.dev/packages/_fe_analyzer_shared) | `meta` |
| `analyzer` | 13.3.0 | [pub.dev/analyzer](https://pub.dev/packages/analyzer) | `_fe_analyzer_shared`, `collection`, `convert`, `crypto`, `glob`, `meta`, `package_config`, `path`, `pub_semver`, `source_span`, `watcher`, `yaml` |
| `args` | 2.7.0 | [pub.dev/args](https://pub.dev/packages/args) | None |
| `async` | 2.13.1 | [pub.dev/async](https://pub.dev/packages/async) | `collection`, `meta` |
| `boolean_selector` | 2.1.2 | [pub.dev/boolean_selector](https://pub.dev/packages/boolean_selector) | `source_span`, `string_scanner` |
| `characters` | 1.4.1 | [pub.dev/characters](https://pub.dev/packages/characters) | None |
| `cli_config` | 0.2.0 | [pub.dev/cli_config](https://pub.dev/packages/cli_config) | `args`, `yaml` |
| `cli_util` | 0.6.0 | [pub.dev/cli_util](https://pub.dev/packages/cli_util) | `ffi`, `meta`, `path` |
| `clock` | 1.1.3 | [pub.dev/clock](https://pub.dev/packages/clock) | None |
| `code_assets` | 2.1.0 | [pub.dev/code_assets](https://pub.dev/packages/code_assets) | `collection`, `hooks`, `logging` |
| `collection` | 1.19.1 | [pub.dev/collection](https://pub.dev/packages/collection) | None |
| `convert` | 3.1.2 | [pub.dev/convert](https://pub.dev/packages/convert) | `typed_data` |
| `coverage` | 1.16.0 | [pub.dev/coverage](https://pub.dev/packages/coverage) | `args`, `cli_config`, `cli_util`, `glob`, `logging`, `meta`, `package_config`, `path`, `source_maps`, `stack_trace`, `vm_service`, `yaml` |
| `crypto` | 3.0.8 | [pub.dev/crypto](https://pub.dev/packages/crypto) | None |
| `fake_async` | 1.3.3 | [pub.dev/fake_async](https://pub.dev/packages/fake_async) | `clock`, `collection` |
| `ffi` | 2.2.0 | [pub.dev/ffi](https://pub.dev/packages/ffi) | None |
| `ffi_leak_tracker` | 0.1.2 | [pub.dev/ffi_leak_tracker](https://pub.dev/packages/ffi_leak_tracker) | `ffi` |
| `file` | 7.0.1 | [pub.dev/file](https://pub.dev/packages/file) | `meta`, `path` |
| `flutter` | 0.0.0 | Official installed Dart/Flutter SDK | `characters`, `collection`, `material_color_utilities`, `meta`, `vector_math`, `sky_engine` |
| `flutter_secure_storage` | 11.2.0 | [pub.dev/flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) | `flutter`, `flutter_secure_storage_darwin`, `flutter_secure_storage_linux`, `flutter_secure_storage_platform_interface`, `flutter_secure_storage_web`, `flutter_secure_storage_windows`, `meta` |
| `flutter_secure_storage_darwin` | 0.4.3 | [pub.dev/flutter_secure_storage_darwin](https://pub.dev/packages/flutter_secure_storage_darwin) | `flutter`, `plugin_platform_interface` |
| `flutter_secure_storage_linux` | 3.0.3 | [pub.dev/flutter_secure_storage_linux](https://pub.dev/packages/flutter_secure_storage_linux) | `flutter`, `flutter_secure_storage_platform_interface` |
| `flutter_secure_storage_platform_interface` | 2.1.1 | [pub.dev/flutter_secure_storage_platform_interface](https://pub.dev/packages/flutter_secure_storage_platform_interface) | `flutter`, `plugin_platform_interface` |
| `flutter_secure_storage_web` | 2.1.1 | [pub.dev/flutter_secure_storage_web](https://pub.dev/packages/flutter_secure_storage_web) | `flutter`, `flutter_secure_storage_platform_interface`, `flutter_web_plugins`, `web` |
| `flutter_secure_storage_windows` | 4.2.2 | [pub.dev/flutter_secure_storage_windows](https://pub.dev/packages/flutter_secure_storage_windows) | `ffi`, `flutter`, `flutter_secure_storage_platform_interface`, `path`, `path_provider`, `path_provider_platform_interface`, `win32` |
| `flutter_test` | 0.0.0 | Official installed Dart/Flutter SDK | `flutter`, `test_api`, `matcher`, `path`, `fake_async`, `clock`, `stack_trace`, `vector_math`, `leak_tracker_flutter_testing`, `collection`, `meta`, `stream_channel` |
| `flutter_web_plugins` | 0.0.0 | Official installed Dart/Flutter SDK | `flutter` |
| `frontend_server_client` | 4.2.0 | [pub.dev/frontend_server_client](https://pub.dev/packages/frontend_server_client) | `async`, `package_config`, `path` |
| `glob` | 2.2.0 | [pub.dev/glob](https://pub.dev/packages/glob) | `async`, `collection`, `file`, `path`, `string_scanner` |
| `hooks` | 2.2.0 | [pub.dev/hooks](https://pub.dev/packages/hooks) | `collection`, `crypto`, `logging`, `pub_semver`, `record_use`, `yaml` |
| `http_multi_server` | 3.2.3 | [pub.dev/http_multi_server](https://pub.dev/packages/http_multi_server) | `async` |
| `http_parser` | 4.1.2 | [pub.dev/http_parser](https://pub.dev/packages/http_parser) | `collection`, `source_span`, `string_scanner`, `typed_data` |
| `io` | 1.1.0 | [pub.dev/io](https://pub.dev/packages/io) | `meta`, `path`, `string_scanner` |
| `jni` | 1.1.2 | [pub.dev/jni](https://pub.dev/packages/jni) | `args`, `collection`, `ffi`, `jni_util`, `meta`, `package_config`, `path`, `plugin_platform_interface` |
| `jni_flutter` | 1.0.4+1 | [pub.dev/jni_flutter](https://pub.dev/packages/jni_flutter) | `flutter`, `jni` |
| `jni_util` | 1.0.0 | [pub.dev/jni_util](https://pub.dev/packages/jni_util) | `path` |
| `leak_tracker` | 11.0.2 | [pub.dev/leak_tracker](https://pub.dev/packages/leak_tracker) | `clock`, `collection`, `meta`, `path`, `vm_service` |
| `leak_tracker_flutter_testing` | 3.0.10 | [pub.dev/leak_tracker_flutter_testing](https://pub.dev/packages/leak_tracker_flutter_testing) | `flutter`, `leak_tracker`, `leak_tracker_testing`, `matcher`, `meta` |
| `leak_tracker_testing` | 3.0.2 | [pub.dev/leak_tracker_testing](https://pub.dev/packages/leak_tracker_testing) | `leak_tracker`, `matcher`, `meta` |
| `logging` | 1.3.0 | [pub.dev/logging](https://pub.dev/packages/logging) | None |
| `matcher` | 0.12.20 | [pub.dev/matcher](https://pub.dev/packages/matcher) | `async`, `meta`, `stack_trace`, `term_glyph`, `test_api` |
| `material_color_utilities` | 0.13.0 | [pub.dev/material_color_utilities](https://pub.dev/packages/material_color_utilities) | `collection` |
| `meta` | 1.19.0 | [pub.dev/meta](https://pub.dev/packages/meta) | None |
| `mime` | 2.1.0 | [pub.dev/mime](https://pub.dev/packages/mime) | None |
| `node_preamble` | 2.0.2 | [pub.dev/node_preamble](https://pub.dev/packages/node_preamble) | None |
| `objective_c` | 9.6.2 | [pub.dev/objective_c](https://pub.dev/packages/objective_c) | `code_assets`, `collection`, `ffi`, `hooks`, `logging`, `meta`, `pub_semver` |
| `package_config` | 2.2.0 | [pub.dev/package_config](https://pub.dev/packages/package_config) | `path` |
| `path` | 1.9.1 | [pub.dev/path](https://pub.dev/packages/path) | None |
| `path_provider` | 2.1.6 | [pub.dev/path_provider](https://pub.dev/packages/path_provider) | `flutter`, `path_provider_android`, `path_provider_foundation`, `path_provider_linux`, `path_provider_platform_interface`, `path_provider_windows` |
| `path_provider_android` | 2.3.1 | [pub.dev/path_provider_android](https://pub.dev/packages/path_provider_android) | `flutter`, `jni`, `jni_flutter`, `path_provider_platform_interface` |
| `path_provider_foundation` | 2.6.0 | [pub.dev/path_provider_foundation](https://pub.dev/packages/path_provider_foundation) | `ffi`, `flutter`, `objective_c`, `path_provider_platform_interface` |
| `path_provider_linux` | 2.2.2 | [pub.dev/path_provider_linux](https://pub.dev/packages/path_provider_linux) | `ffi`, `flutter`, `path`, `path_provider_platform_interface`, `xdg_directories` |
| `path_provider_platform_interface` | 2.1.3 | [pub.dev/path_provider_platform_interface](https://pub.dev/packages/path_provider_platform_interface) | `flutter`, `platform`, `plugin_platform_interface` |
| `path_provider_windows` | 2.3.0 | [pub.dev/path_provider_windows](https://pub.dev/packages/path_provider_windows) | `ffi`, `flutter`, `path`, `path_provider_platform_interface` |
| `platform` | 3.2.0 | [pub.dev/platform](https://pub.dev/packages/platform) | `meta` |
| `plugin_platform_interface` | 2.1.8 | [pub.dev/plugin_platform_interface](https://pub.dev/packages/plugin_platform_interface) | `meta` |
| `pool` | 1.5.3 | [pub.dev/pool](https://pub.dev/packages/pool) | `async`, `stack_trace` |
| `pub_semver` | 2.2.1 | [pub.dev/pub_semver](https://pub.dev/packages/pub_semver) | `collection` |
| `record_use` | 1.1.1 | [pub.dev/record_use](https://pub.dev/packages/record_use) | `collection`, `meta`, `pub_semver` |
| `remote_core` | 0.1.0 | Repository-owned workspace | `test` |
| `remote_lg_webos` | 0.1.0 | Repository-owned workspace | `remote_core`, `remote_network`, `test` |
| `remote_network` | 0.1.0 | Repository-owned workspace | `test` |
| `route_definer` | 4.0.0 | [DEVCOM Git revision 7546848](https://github.com/arlamend7/flutter_route_definer/commit/7546848c78ab81a208655ad7083f608942309b63) | `flutter`, `meta` |
| `shelf` | 1.4.3 | [pub.dev/shelf](https://pub.dev/packages/shelf) | `async`, `collection`, `http_parser`, `path`, `stack_trace`, `stream_channel` |
| `shelf_packages_handler` | 3.0.2 | [pub.dev/shelf_packages_handler](https://pub.dev/packages/shelf_packages_handler) | `path`, `shelf`, `shelf_static` |
| `shelf_static` | 1.2.0 | [pub.dev/shelf_static](https://pub.dev/packages/shelf_static) | `convert`, `http_parser`, `mime`, `path`, `shelf` |
| `shelf_web_socket` | 3.0.0 | [pub.dev/shelf_web_socket](https://pub.dev/packages/shelf_web_socket) | `shelf`, `stream_channel`, `web_socket_channel` |
| `sky_engine` | 0.0.0 | Official installed Dart/Flutter SDK | None |
| `source_map_stack_trace` | 2.1.2 | [pub.dev/source_map_stack_trace](https://pub.dev/packages/source_map_stack_trace) | `path`, `source_maps`, `stack_trace` |
| `source_maps` | 0.10.14 | [pub.dev/source_maps](https://pub.dev/packages/source_maps) | `source_span` |
| `source_span` | 1.10.2 | [pub.dev/source_span](https://pub.dev/packages/source_span) | `collection`, `path`, `term_glyph` |
| `stack_trace` | 1.12.2 | [pub.dev/stack_trace](https://pub.dev/packages/stack_trace) | `path` |
| `stream_channel` | 2.1.4 | [pub.dev/stream_channel](https://pub.dev/packages/stream_channel) | `async` |
| `string_scanner` | 1.4.1 | [pub.dev/string_scanner](https://pub.dev/packages/string_scanner) | `source_span` |
| `term_glyph` | 1.2.2 | [pub.dev/term_glyph](https://pub.dev/packages/term_glyph) | None |
| `test` | 1.31.1 | [pub.dev/test](https://pub.dev/packages/test) | `analyzer`, `async`, `boolean_selector`, `collection`, `coverage`, `http_multi_server`, `io`, `matcher`, `node_preamble`, `package_config`, `path`, `pool`, `shelf`, `shelf_packages_handler`, `shelf_static`, `shelf_web_socket`, `source_span`, `stack_trace`, `stream_channel`, `test_api`, `test_core`, `typed_data`, `web_socket_channel`, `webkit_inspection_protocol`, `yaml` |
| `test_api` | 0.7.12 | [pub.dev/test_api](https://pub.dev/packages/test_api) | `async`, `boolean_selector`, `collection`, `meta`, `source_span`, `stack_trace`, `stream_channel`, `string_scanner`, `term_glyph` |
| `test_core` | 0.6.18 | [pub.dev/test_core](https://pub.dev/packages/test_core) | `analyzer`, `args`, `async`, `boolean_selector`, `collection`, `coverage`, `frontend_server_client`, `glob`, `io`, `meta`, `package_config`, `path`, `pool`, `source_map_stack_trace`, `source_maps`, `source_span`, `stack_trace`, `stream_channel`, `test_api`, `vm_service`, `yaml` |
| `typed_data` | 1.4.0 | [pub.dev/typed_data](https://pub.dev/packages/typed_data) | `collection` |
| `universal_remote_app` | 0.1.0+1 | Repository-owned workspace | `flutter`, `remote_core`, `remote_network`, `remote_lg_webos`, `flutter_secure_storage`, `route_definer`, `flutter_test` |
| `universal_remote_workspace` | 0.0.0 | Repository-owned workspace | `test`, `remote_core`, `remote_lg_webos`, `remote_network` |
| `vector_math` | 2.4.3 | [pub.dev/vector_math](https://pub.dev/packages/vector_math) | None |
| `vm_service` | 15.4.0 | [pub.dev/vm_service](https://pub.dev/packages/vm_service) | None |
| `watcher` | 1.2.1 | [pub.dev/watcher](https://pub.dev/packages/watcher) | `async`, `path` |
| `web` | 1.1.2 | [pub.dev/web](https://pub.dev/packages/web) | None |
| `web_socket` | 1.0.1 | [pub.dev/web_socket](https://pub.dev/packages/web_socket) | `web` |
| `web_socket_channel` | 3.0.3 | [pub.dev/web_socket_channel](https://pub.dev/packages/web_socket_channel) | `async`, `crypto`, `stream_channel`, `web`, `web_socket` |
| `webkit_inspection_protocol` | 1.2.1 | [pub.dev/webkit_inspection_protocol](https://pub.dev/packages/webkit_inspection_protocol) | `logging` |
| `win32` | 6.4.0 | [pub.dev/win32](https://pub.dev/packages/win32) | `ffi`, `ffi_leak_tracker`, `meta` |
| `xdg_directories` | 1.1.0 | [pub.dev/xdg_directories](https://pub.dev/packages/xdg_directories) | `meta`, `path` |
| `yaml` | 3.1.4 | [pub.dev/yaml](https://pub.dev/packages/yaml) | `collection`, `source_span`, `string_scanner` |
