#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "${ROOT_DIR}/script/use_xcode_toolchain.sh"
MODEL="${1:-base.en}"
BUILD_CONFIGURATION="${BUILD_CONFIGURATION:-debug}"
APP_SUPPORT_DIR="${HOME}/Library/Application Support/Wisp"
MODEL_PATH="${APP_SUPPORT_DIR}/Models/ggml-${MODEL}.bin"
TMP_DIR="$(mktemp -d)"
SAMPLE_WAV="${TMP_DIR}/sample.wav"
SMOKE_BINARY="${TMP_DIR}/whisper-smoke"
SAMPLE_URL="https://raw.githubusercontent.com/ggml-org/whisper.cpp/master/samples/jfk.wav"

cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

find_whisper_framework() {
  find "${ROOT_DIR}/.build" -path "*/${BUILD_CONFIGURATION}/whisper.framework" -print -quit 2>/dev/null || true
}

echo "==> Building Wisp bundle"
BUILD_CONFIGURATION="${BUILD_CONFIGURATION}" "${ROOT_DIR}/script/build_and_run.sh" --build-only

echo "==> Ensuring model ${MODEL}"
"${ROOT_DIR}/script/bootstrap_model.sh" "${MODEL}"

echo "==> Generating speech sample"
curl -L --fail --silent --show-error -o "${SAMPLE_WAV}" "${SAMPLE_URL}"

BUILD_FRAMEWORK_DIR="$(find_whisper_framework)"
if [[ -z "${BUILD_FRAMEWORK_DIR}" ]]; then
  echo "Unable to locate whisper.framework for configuration ${BUILD_CONFIGURATION}" >&2
  exit 1
fi
BUILD_FRAMEWORK_DIR="$(dirname "${BUILD_FRAMEWORK_DIR}")"

echo "==> Compiling smoke test"
xcrun swiftc \
  -F "${BUILD_FRAMEWORK_DIR}" \
  -framework whisper \
  -Xlinker -rpath -Xlinker "${BUILD_FRAMEWORK_DIR}" \
  -o "${SMOKE_BINARY}" \
  "${ROOT_DIR}/script/whisper_smoke_test.swift"

echo "==> Running smoke test"
"${SMOKE_BINARY}" "${MODEL_PATH}" "${SAMPLE_WAV}"
