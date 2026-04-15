# Wisp

Wisp is a native macOS SwiftUI scaffold for a local-first dictation app in the spirit of Superwhisper.

Project docs live in `docs/`, and repo-level project guidance lives in `AGENTS.md`.

## What is here

- A package-first SwiftUI macOS app
- Explicit Mac scenes for the main window, settings, and a menu bar extra
- Local recording, model download, and on-device Whisper transcription
- Persistent local transcript history
- A global `Command-Shift-D` dictation hotkey
- A cleaner desktop-native workspace UI with model, history, and permission surfaces
- A project-local `script/build_and_run.sh` entrypoint that builds and bundles a `.app`
- Lightweight `Logger` hooks for app lifecycle and dictation state

## Build and run

```sh
./script/build_and_run.sh
```

Useful options:

```sh
./script/build_and_run.sh --build-only
./script/build_and_run.sh --logs
```

## Self-contained setup

Wisp does not require a separate Whisper app on the machine. The bundled app carries the Whisper runtime framework, and the model is downloaded into `~/Library/Application Support/Wisp/Models`.

The local scripts auto-detect `/Applications/Xcode.app` and prefer the full Xcode toolchain when it is installed, while still keeping the workflow shell-first.

Useful unattended commands:

```sh
./script/bootstrap_model.sh base.en
./script/health_check.sh base.en
./script/overnight_setup.sh base.en
```

Release-prep and bundle inspection:

```sh
./script/archive_and_inspect.sh
./script/inspect_bundle.sh .build/release/Wisp.app
```

See [`docs/RELEASE_PREP.md`](docs/RELEASE_PREP.md) for the bundle, plist, entitlements, and codesign inspection commands.

## Next steps

1. Replace file-based recording with lower-latency streaming capture.
2. Tighten insertion targeting and permission recovery flows.
3. Add packaging, signing, and notarization steps for distribution.
