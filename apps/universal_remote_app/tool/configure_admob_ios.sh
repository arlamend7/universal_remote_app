#!/bin/sh
set -eu

cd "$(dirname "$0")/.."
app_id=$(sed -n 's/^ADMOB_IOS_APP_ID=//p' .env)
if ! printf '%s\n' "$app_id" | grep -Eq '^ca-app-pub-[0-9]+~[0-9]+$'; then
  printf '%s\n' 'Set ADMOB_IOS_APP_ID to an AdMob App ID in .env.' >&2
  exit 1
fi

printf 'ADMOB_IOS_APP_ID = %s\n' "$app_id" > ios/Flutter/AdMob.local.xcconfig
