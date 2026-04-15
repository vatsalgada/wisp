#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MODEL="${1:-base.en}"

echo "==> Running overnight setup with ${MODEL}"
"${ROOT_DIR}/script/health_check.sh" "${MODEL}"
"${ROOT_DIR}/script/build_and_run.sh"
echo "Wisp is built, verified, and launched."
