# Releasing FoldBar

Release assets are built locally with a Developer ID Application certificate,
a secure timestamp, and hardened runtime. Apple notarization and Gatekeeper
checks must pass before the release is published. CI performs ad-hoc builds and
unit tests only; it does not have signing credentials.

## Prerequisites

- Xcode selected with `xcode-select`, Python 3, and GitHub CLI.
- Developer ID Application certificate and its private key in your keychain.
- A notarytool Keychain profile, or an App Store Connect team API key authorized
  for notarization. Keep credentials outside this repository.

```sh
export FOLDBAR_SIGN_IDENTITY='Developer ID Application: Your Name (TEAMID)'
export FOLDBAR_NOTARY_PROFILE='your-existing-profile'
./scripts/release.sh
```

Alternatively, set `ASC_API_KEY_ID`, `ASC_API_ISSUER_ID`, and `ASC_API_KEY_PATH`
(the path to a `.p8` file), leaving `FOLDBAR_NOTARY_PROFILE` unset. Do not paste
secrets into a pull request, release, or issue.

## What the script does

1. Run boundary tests and compile the app for arm64.
2. Sign with hardened runtime and a secure Apple timestamp.
3. Submit an app ZIP to Apple, require `Accepted`, and staple the app ticket.
4. Verify app signature and Gatekeeper acceptance.
5. Create a drag-to-Applications DMG, sign it, notarize it, and staple its ticket.
6. Verify the DMG, package the stapled app as a ZIP, and generate verification
   details and SHA-256 checksums under `dist/<version>/`.

A failed or timed-out step must be investigated. Never label an unaccepted
submission as notarized. `xcrun notarytool info` / `log` can inspect a submission
ID using the same authentication arguments. Do not modify the app after signing
or the DMG after stapling.

## Publishing

Update `Info.plist` (version and build), displayed versions in
`Sources/Settings.swift`, and documentation. Run the script from the source
commit being released. Smoke-test the installed app on macOS 27 with real icons,
and review the README's compatibility notes.

Tag that commit, push the tag, and create a GitHub release with:

- `FoldBar-<version>-arm64.dmg`
- `FoldBar-<version>-arm64.zip`
- `FoldBar-<version>-source.tar.gz` from `git archive <tag>`
- `VERIFICATION.txt`
- `SHA256SUMS.txt` (regenerate after adding the source archive)

Use a release notes file with `gh release create --notes-file`. Do not publish
build directories, credentials, historical local packages, or unrelated logs.
Source for the exact release is also available through GitHub's tag archives.

## Checking a download

```sh
shasum -a 256 -c SHA256SUMS.txt
codesign --verify --deep --strict /Applications/FoldBar.app
spctl --assess --type execute --verbose=4 /Applications/FoldBar.app
xcrun stapler validate /Applications/FoldBar.app
```

Keep the bundle identifier and release signing identity stable between updates
so existing Accessibility grants can continue to recognize the app.
