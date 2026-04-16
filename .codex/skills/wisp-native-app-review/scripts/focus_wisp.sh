#!/bin/zsh

set -euo pipefail

APP_NAME="${APP_NAME:-Wisp}"

osascript <<APPLESCRIPT
tell application "$APP_NAME" to activate
delay 0.2
try
  tell application "System Events"
    set frontmost of process "$APP_NAME" to true
  end tell
end try
APPLESCRIPT
