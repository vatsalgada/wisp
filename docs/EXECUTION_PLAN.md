# Execution Plan

## Objective

Get Wisp to a working local dictation MVP with no required user intervention during the build-out. The current phase is about keeping that path healthy while improving polish, packaging confidence, and Mac-native ergonomics.

## Delivery target

A working native macOS app that can:

1. start and stop a dictation session
2. capture microphone audio to a local file
3. run a local speech-to-text runtime against that file
4. show the transcript in the app
5. copy or insert the transcript into the active app

## Implementation path

### Milestone 1: App foundation

- Add app-owned state for dictation sessions, runtime status, transcripts, and errors
- Add clear UI status for readiness, recording, transcription, and permission state
- Add unified logging around the main state transitions

Health check:

- App builds
- App launches
- State changes are visible in the UI
- Logger emits app and model events

### Milestone 2: Audio capture

- Add microphone permission checks and request flow
- Implement local microphone recording to a WAV file
- Add start and stop controls that produce a real audio artifact

Health check:

- Recording starts and stops without crashing
- A WAV file is written to an app-managed directory
- Failure cases are surfaced cleanly in the UI

### Milestone 3: Runtime bootstrap

- Bundle the official `whisper.cpp` runtime into the app build
- Add model download and cache location management
- Add shell scripts for unattended setup and verification

Health check:

- Bootstrap script completes on this machine
- Runtime binary is present
- Model file is present
- A manual CLI transcription succeeds on a sample WAV file

### Milestone 4: App transcription pipeline

- Add a `TranscriptionRuntime` abstraction
- Add a first implementation backed by the bundled `whisper.cpp` framework
- Wire recording output into transcription and final transcript display

Health check:

- App can transcribe a freshly recorded clip
- Transcript appears in the main window
- Errors are observable and recoverable

### Milestone 5: Insertion and polish

- Add accessibility trust checks
- Add pasteboard copy and best-effort text insertion into the active app
- Add basic controls in the menu bar and main window

Health check:

- Transcript can be copied reliably
- Insertion path works when accessibility permissions are granted
- Permission gaps are explained in the UI

### Milestone 6: Overnight operability

- Add a repeatable script path for build, bootstrap, and run
- Document how to run logs and where artifacts live
- Re-run milestone validations after all major changes
- Prefer the full Xcode toolchain automatically when it is installed locally

Health check:

- Build passes from a cold run
- Runtime bootstrap is scriptable
- App launches and logs status
- Repo docs match the shipped flow

## Risk management

- Keep the runtime behind app-owned abstractions so we can replace it later
- Avoid Xcode project conversion unless SwiftPM becomes a blocker
- Use small milestone validations instead of a single big-bang test at the end
- Keep bundle verification and transcription smoke tests runnable without opening Xcode

## Success criteria for the morning

- The app compiles and launches locally
- The runtime bootstrap path is documented and scriptable
- A dictated clip can become a local transcript
- The transcript can be surfaced and copied or inserted
- The repo contains enough docs for the next session to continue cleanly
