# Project Notes

## Vision

Wisp is an open-source macOS dictation app built around local transcription, low friction, and strong desktop-native UX. The app should feel fast to invoke, simple to trust, and easy to extend.

## Core product ideas

- Local-first transcription by default
- A fast start/stop flow with minimal UI friction
- A menu bar presence for lightweight control
- Strong keyboard-driven workflows
- Clean insertion into the currently active app
- Pluggable runtime architecture so the app stays in control of the experience

## Current decisions

- Native macOS app using SwiftUI
- Shell-first local build loop using `swift build`
- Package-first project layout
- Main window + settings + menu bar extra as explicit scenes
- Current unattended model default: `base.en`
- Runtime direction: use the official `whisper.cpp` runtime first, keep the rest of the pipeline ours
- Prefer the full Xcode toolchain automatically when `/Applications/Xcode.app` is present
- Ship a self-contained `.app` bundle that embeds the runtime and manages models under app support

## Design principles

- Prioritize latency and reliability over squeezing out maximum model quality
- Prefer standard macOS patterns before introducing custom chrome
- Keep privacy legible in both implementation and product messaging
- Hide runtime-specific details behind app-owned interfaces
- Bundle what we can into the app so another Mac does not need a separate Whisper install

## Open questions

- How aggressive partial transcripts should be
- Whether text post-processing should run automatically or be optional
- How much model management should live in the main window versus settings
- When to introduce a compact transient dictation HUD
