#!/bin/zsh

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 /path/to/Wisp.app" >&2
  exit 1
fi

BUNDLE_INPUT="$1"
if [[ ! -d "$BUNDLE_INPUT" ]]; then
  echo "Bundle not found: $BUNDLE_INPUT" >&2
  exit 1
fi

BUNDLE_PATH="$(cd "$BUNDLE_INPUT" && pwd -P)"
CONTENTS_PATH="$BUNDLE_PATH/Contents"
INFO_PLIST="$CONTENTS_PATH/Info.plist"
EXECUTABLE_NAME="$(basename "$BUNDLE_PATH" .app)"
EXECUTABLE_PATH="$CONTENTS_PATH/MacOS/$EXECUTABLE_NAME"

run_optional() {
  local label="$1"
  shift

  printf '\n==> %s\n' "$label"
  set +e
  "$@"
  local exit_code=$?
  set -e

  if [[ $exit_code -ne 0 ]]; then
    printf '(command exited %d)\n' "$exit_code"
  fi
}

echo "Bundle: $BUNDLE_PATH"

run_optional "Info.plist" plutil -p "$INFO_PLIST"
run_optional "Code signature details" codesign -dv --verbose=4 "$BUNDLE_PATH"
run_optional "Code signature verification" codesign --verify --deep --strict --verbose=4 "$BUNDLE_PATH"
run_optional "Embedded entitlements" codesign -d --entitlements :- "$BUNDLE_PATH"
run_optional "Quarantine attributes" xattr -lr "$BUNDLE_PATH"
run_optional "Linked libraries" otool -L "$EXECUTABLE_PATH"
