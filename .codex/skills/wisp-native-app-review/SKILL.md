---
name: wisp-native-app-review
description: Use when working on Wisp's native macOS app shell, layout, UX, or visual polish and you need to interact with the real running app, capture the actual Wisp window, inspect window metadata, or review the live UI instead of guessing from code alone.
---

# Wisp Native App Review

Use this skill for Wisp UI, layout, window-shell, scrolling, or interaction work where live app inspection matters.

Prefer the real app loop over code-only reasoning:

1. Rebuild and relaunch Wisp.
2. Bring Wisp frontmost.
3. Capture the actual Wisp window, not a full-desktop screenshot.
4. Patch the UI.
5. Rebuild, relaunch, and capture again.

## Primary commands

From the repo root:

```bash
./script/build_and_run.sh
./.codex/skills/wisp-native-app-review/scripts/focus_wisp.sh
./.codex/skills/wisp-native-app-review/scripts/window_info.sh
./.codex/skills/wisp-native-app-review/scripts/capture_wisp_window.sh
./.codex/skills/wisp-native-app-review/scripts/resize_wisp_window.sh 1200 820
```

Screenshots are saved to `artifacts/ui/`.

## Review workflow

### 1. Always validate the live app, not just the code

- Use `./script/build_and_run.sh` whenever the bundle may be stale.
- If a screenshot seems wrong, assume the wrong app or wrong space may have been captured until proven otherwise.
- Prefer direct Wisp-window capture over whole-screen capture.

### 2. Use the helper scripts in this skill

- `focus_wisp.sh`
  Brings Wisp frontmost.
- `window_info.sh`
  Prints the live Wisp window id and bounds using CoreGraphics.
- `capture_wisp_window.sh`
  Captures the real Wisp window by window id.
- `resize_wisp_window.sh WIDTH HEIGHT`
  Resizes the front Wisp window for responsive checks.

### 3. When debugging top clipping or shell issues

- First run `window_info.sh` and `capture_wisp_window.sh`.
- If the live Wisp window screenshot looks correct but a full-screen screenshot looks wrong, trust the direct window capture.
- Treat title-bar/safe-area bugs separately from scroll-position bugs.
- If the app opens mid-scroll, verify scroll restoration before changing top padding again.

### 4. When debugging scroll behavior

- Capture both the initial app state and the post-scroll state.
- Avoid nested vertical scroll containers when possible.
- For page views, prefer one page-level vertical scroll owner unless there is a strong reason not to.

### 5. When reviewing UX quality

Check these in the live app:

- Is the top of each page visible on launch?
- Can the window resize narrower and taller without trapping content?
- Do sidebar and page scroll regions behave predictably?
- Are hit areas full-width and easy to click?
- Does hover/motion feel subtle and deliberate rather than noisy?
- Does the visual hierarchy make the primary action obvious?

## Accessibility and permissions

Some automation depends on macOS permissions:

- `focus_wisp.sh` and `resize_wisp_window.sh` may need Accessibility permission for the shell host running commands.
- `capture_wisp_window.sh` and `window_info.sh` do not depend on full UI tree inspection and are the most reliable screenshot/debug tools.

If Accessibility-driven commands fail, continue using:

```bash
./.codex/skills/wisp-native-app-review/scripts/window_info.sh
./.codex/skills/wisp-native-app-review/scripts/capture_wisp_window.sh
```

## Expected practice for Wisp work

- Do not rely on full-desktop screenshots when a direct window capture is available.
- Do not claim a shell/layout fix worked until a fresh direct Wisp-window capture confirms it.
- Prefer small iterative visual checks after each shell/layout patch.
- Use this skill whenever the task is about native app behavior, not just SwiftUI code structure.
