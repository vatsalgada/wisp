#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../../../.." && pwd)"
OUT_DIR="${ROOT_DIR}/artifacts/ui"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT_PATH="${1:-${OUT_DIR}/wisp-window-${STAMP}.png}"
APP_NAME="${APP_NAME:-Wisp}"

mkdir -p "$OUT_DIR"

WINDOW_ID="$(APP_NAME="$APP_NAME" "${ROOT_DIR}/.codex/skills/wisp-native-app-review/scripts/window_info.sh" | awk -F= '/^window_id=/{print $2}')"

if [[ -z "${WINDOW_ID}" ]]; then
  echo "Could not find a live ${APP_NAME} window id." >&2
  exit 1
fi

screencapture -x -l "$WINDOW_ID" "$OUT_PATH"
echo "$OUT_PATH"
