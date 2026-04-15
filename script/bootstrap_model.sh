#!/bin/zsh

set -euo pipefail

MODEL="${1:-base.en}"
APP_SUPPORT_DIR="${HOME}/Library/Application Support/Wisp"
MODELS_DIR="${APP_SUPPORT_DIR}/Models"
MODEL_FILE="ggml-${MODEL}.bin"
MODEL_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/${MODEL_FILE}"
DESTINATION="${MODELS_DIR}/${MODEL_FILE}"

mkdir -p "${MODELS_DIR}"

if [[ -f "${DESTINATION}" ]]; then
  echo "Model already present at ${DESTINATION}"
  exit 0
fi

echo "==> Downloading ${MODEL}"
curl -L --fail --progress-bar -o "${DESTINATION}" "${MODEL_URL}"
echo "Saved model to ${DESTINATION}"
