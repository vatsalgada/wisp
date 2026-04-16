#!/bin/zsh

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 WIDTH HEIGHT" >&2
  exit 1
fi

WIDTH="$1"
HEIGHT="$2"
APP_NAME="${APP_NAME:-Wisp}"

osascript <<APPLESCRIPT
tell application "System Events"
  tell process "$APP_NAME"
    tell front window
      set size to {$WIDTH, $HEIGHT}
      return size
    end tell
  end tell
end tell
APPLESCRIPT
