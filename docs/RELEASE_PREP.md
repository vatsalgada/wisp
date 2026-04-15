# Release Prep

Use the shell-first archive path when you want a distributable local bundle and a quick inspection of the package state.

## Archive and inspect

```sh
./script/archive_and_inspect.sh
```

The script:

1. builds the app bundle with `swift build`
2. stages a clean `.app` bundle under `artifacts/releases/`
3. inspects the plist, code signature, entitlements, quarantine flags, and linked libraries
4. optionally zips the staged bundle for handoff

Useful flags:

```sh
./script/archive_and_inspect.sh --skip-zip
./script/archive_and_inspect.sh --skip-inspect
BUILD_CONFIGURATION=debug ./script/archive_and_inspect.sh
```

## Inspect an existing bundle

```sh
./script/inspect_bundle.sh /path/to/Wisp.app
```

That inspection path reports:

- `Contents/Info.plist` via `plutil -p`
- signature metadata via `codesign -dv --verbose=4`
- verification via `codesign --verify --deep --strict --verbose=4`
- embedded entitlements via `codesign -d --entitlements :-`
- quarantine state via `xattr -lr`
- linked libraries via `otool -L`

## Manual checks

If you want to inspect a bundle by hand, these are the same commands the script uses:

```sh
plutil -p /path/to/Wisp.app/Contents/Info.plist
codesign -dv --verbose=4 /path/to/Wisp.app
codesign --verify --deep --strict --verbose=4 /path/to/Wisp.app
codesign -d --entitlements :- /path/to/Wisp.app
xattr -lr /path/to/Wisp.app
otool -L /path/to/Wisp.app/Contents/MacOS/Wisp
```

For a locally ad hoc-signed bundle, `spctl --assess` may report a failure even when the bundle is structurally valid. Use it as an informational check, not the only gate.
