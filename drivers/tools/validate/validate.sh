#!/usr/bin/env sh
# Validates one schema-2 integration folder with the compiled runtime engines
# and prints its manifest and files as JSON.
set -eu
repo=$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)
exec dart run "$repo/packages/remote_driver_runtime/bin/validate_driver.dart" "$@"
