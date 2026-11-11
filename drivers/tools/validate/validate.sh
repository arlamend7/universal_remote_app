#!/usr/bin/env sh
set -eu
repo=$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)
exec dart run "$repo/packages/remote_driver_runtime/bin/validate_driver.dart" --enable-local-drivers "$@"
