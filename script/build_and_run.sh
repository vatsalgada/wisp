#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "${ROOT_DIR}/script/use_xcode_toolchain.sh"
APP_NAME="Wisp"
BUILD_CONFIGURATION="${BUILD_CONFIGURATION:-debug}"
BUILD_DIR="$ROOT_DIR/.build/${BUILD_CONFIGURATION}"
EXECUTABLE_PATH="$BUILD_DIR/$APP_NAME"
APP_BUNDLE_PATH="$BUILD_DIR/$APP_NAME.app"
CONTENTS_PATH="$APP_BUNDLE_PATH/Contents"
MACOS_PATH="$CONTENTS_PATH/MacOS"
RESOURCES_PATH="$CONTENTS_PATH/Resources"
FRAMEWORKS_PATH="$CONTENTS_PATH/Frameworks"
INFO_PLIST_SOURCE="$ROOT_DIR/Config/Wisp-Info.plist"

find_whisper_framework() {
  local framework_path
  framework_path="$(find "$ROOT_DIR/.build" -path "*/${BUILD_CONFIGURATION}/whisper.framework" -print -quit 2>/dev/null || true)"
  if [[ -n "$framework_path" ]]; then
    echo "$framework_path"
    return 0
  fi

  return 1
}

binary_has_framework_rpath() {
  otool -l "$1" 2>/dev/null | grep -Fq "@executable_path/../Frameworks"
}

BUILD_ONLY=0
SHOW_LOGS=0

for arg in "$@"; do
  case "$arg" in
    --build-only)
      BUILD_ONLY=1
      ;;
    --logs)
      SHOW_LOGS=1
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      exit 1
      ;;
  esac
done

echo "==> Building $APP_NAME"
xcrun swift build -c "$BUILD_CONFIGURATION"

if [[ ! -x "$EXECUTABLE_PATH" ]]; then
  echo "Expected executable not found at $EXECUTABLE_PATH" >&2
  exit 1
fi

echo "==> Bundling app"
rm -rf "$APP_BUNDLE_PATH"
mkdir -p "$MACOS_PATH" "$RESOURCES_PATH" "$FRAMEWORKS_PATH"
cp "$EXECUTABLE_PATH" "$MACOS_PATH/$APP_NAME"
cp "$INFO_PLIST_SOURCE" "$CONTENTS_PATH/Info.plist"
chmod +x "$MACOS_PATH/$APP_NAME"

WHISPER_FRAMEWORK_SOURCE="$(find_whisper_framework || true)"

if [[ -n "$WHISPER_FRAMEWORK_SOURCE" && -d "$WHISPER_FRAMEWORK_SOURCE" ]]; then
  cp -R "$WHISPER_FRAMEWORK_SOURCE" "$FRAMEWORKS_PATH/"
  if ! binary_has_framework_rpath "$MACOS_PATH/$APP_NAME"; then
    install_name_tool -add_rpath "@executable_path/../Frameworks" "$MACOS_PATH/$APP_NAME"
  fi
fi

codesign --force --deep --sign - --timestamp=none "$APP_BUNDLE_PATH" >/dev/null

if [[ "$BUILD_ONLY" -eq 1 ]]; then
  echo "Built app bundle at $APP_BUNDLE_PATH"
  exit 0
fi

echo "==> Launching $APP_NAME"
pkill -x "$APP_NAME" >/dev/null 2>&1 || true
open "$APP_BUNDLE_PATH"

if [[ "$SHOW_LOGS" -eq 1 ]]; then
  echo "==> Streaming logs for com.wisp.app"
  exec log stream --style compact --predicate 'subsystem == "com.wisp.app"'
fi
