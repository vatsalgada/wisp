#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "${ROOT_DIR}/script/use_xcode_toolchain.sh"

APP_NAME="Wisp"
BUILD_CONFIGURATION="${BUILD_CONFIGURATION:-release}"
OUTPUT_ROOT="${OUTPUT_DIR:-${ROOT_DIR}/artifacts/releases}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
ARCHIVE_NAME="${APP_NAME}-${BUILD_CONFIGURATION}-${TIMESTAMP}"
SOURCE_APP="${ROOT_DIR}/.build/${BUILD_CONFIGURATION}/${APP_NAME}.app"
STAGE_DIR="${OUTPUT_ROOT}/${ARCHIVE_NAME}"
STAGED_APP="${STAGE_DIR}/${APP_NAME}.app"
ZIP_PATH="${OUTPUT_ROOT}/${ARCHIVE_NAME}.zip"

SKIP_ZIP=0
SKIP_INSPECT=0

for arg in "$@"; do
  case "$arg" in
    --skip-zip)
      SKIP_ZIP=1
      ;;
    --skip-inspect)
      SKIP_INSPECT=1
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      exit 1
      ;;
  esac
done

mkdir -p "$OUTPUT_ROOT"

echo "==> Building $APP_NAME ($BUILD_CONFIGURATION)"
BUILD_CONFIGURATION="$BUILD_CONFIGURATION" "${ROOT_DIR}/script/build_and_run.sh" --build-only

if [[ ! -d "$SOURCE_APP" ]]; then
  echo "Expected app bundle not found at $SOURCE_APP" >&2
  exit 1
fi

echo "==> Staging archive bundle"
rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR"
ditto "$SOURCE_APP" "$STAGED_APP"

echo "==> Re-signing staged bundle"
codesign --force --deep --sign - --timestamp=none "$STAGED_APP" >/dev/null

if [[ "$SKIP_INSPECT" -eq 0 ]]; then
  "${ROOT_DIR}/script/inspect_bundle.sh" "$STAGED_APP"
fi

if [[ "$SKIP_ZIP" -eq 0 ]]; then
  echo "==> Creating zip"
  ditto -c -k --sequesterRsrc --keepParent "$STAGED_APP" "$ZIP_PATH"
fi

echo "Archive bundle: $STAGED_APP"
if [[ "$SKIP_ZIP" -eq 0 ]]; then
  echo "Archive zip: $ZIP_PATH"
fi
