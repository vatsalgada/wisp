#!/bin/zsh

set -euo pipefail

APP_NAME="${APP_NAME:-Wisp}"

swift -e '
import Cocoa
import CoreGraphics

let appName = ProcessInfo.processInfo.environment["APP_NAME"] ?? "Wisp"
let list = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] ?? []

let matches = list.compactMap { window -> (Int, String, [String: Any], Int)? in
    guard let owner = window[kCGWindowOwnerName as String] as? String, owner == appName,
          let windowNumber = window[kCGWindowNumber as String] as? Int,
          let bounds = window[kCGWindowBounds as String] as? [String: Any],
          let width = bounds["Width"] as? Int,
          let height = bounds["Height"] as? Int
    else { return nil }

    let name = (window[kCGWindowName as String] as? String) ?? ""
    return (windowNumber, name, bounds, width * height)
}

guard let best = matches.max(by: { $0.3 < $1.3 }) else {
    fputs("No on-screen window found for \(appName)\n", stderr)
    exit(1)
}

print("window_id=\(best.0)")
print("window_name=\(best.1)")
print("bounds=\(best.2)")
'
