# AGENTS.md

## Project

- Name: Wisp
- Type: Native macOS SwiftUI app
- Goal: Build an open-source, local-first dictation app inspired by Superwhisper
- Product stance: Own the app experience, session flow, text handling, and model management while using an existing local transcription runtime underneath
- Packaging rule: The app must work on another Mac without requiring any separate Whisper app install

## Current stack

- Swift 6
- SwiftUI for the app shell and primary UI
- AppKit only when desktop-specific behavior needs a narrow bridge
- Swift Package Manager for the local project structure
- `script/build_and_run.sh` for the default build-and-launch loop

## Product direction

Wisp should feel like a real Mac app first. Prefer explicit scenes, menu commands, keyboard shortcuts, settings, and menu bar access over iOS-style navigation patterns.

The transcription layer should stay behind our own abstraction so we can change runtimes later without rewriting the app. The current unattended setup uses the official `whisper.cpp` XCFramework bundled into the app, with app-managed local ggml model downloads.

## What exists today

- Main app scene with a desktop-native split view
- Settings scene
- Menu bar extra
- Premium desktop-focused dashboard, history, model, and permission views
- Global dictation hotkey
- Persistent transcript history
- Bundled `whisper.cpp` XCFramework runtime with app-managed model downloads
- Real local recording and on-device transcription
- Simple observable app model for dictation state
- Unified logging for basic app events
- A package-first `.app` bundle build loop
- Unattended smoke-test and overnight setup scripts

## Near-term priorities

1. Polish insertion targeting and accessibility recovery
2. Tighten low-latency capture and session UX
3. Add richer history workflows and transcript actions
4. Prepare signing, notarization, and release packaging
5. Add stronger automated validation around runtime and app state

## Working conventions

- Keep the workflow shell-first
- Prefer the full Xcode toolchain automatically when it is available on disk
- Prefer the smallest useful validation loop for each change
- Keep SwiftUI as the source of truth unless AppKit is clearly required
- Favor simple abstractions that let us swap runtimes without touching the rest of the app
- Document product decisions and next steps in `docs/`

## Repo map

- `Sources/`: app code
- `Config/`: bundle metadata and app configuration
- `script/`: local automation and developer entrypoints
- `docs/`: project notes, status, and roadmap
- `.codex/skills/wisp-native-app-review/`: project-local skill for relaunching Wisp, focusing the live app, capturing the actual Wisp window, resizing it for responsive checks, and reviewing the native UI from real screenshots
