#!/bin/bash
# Build, sign, notarize, staple, and verify. This script does not publish.
set -euo pipefail
cd "$(dirname "$0")/.."
: "${FOLDBAR_SIGN_IDENTITY:?Set a Developer ID Application signing identity}"
if [[ "$FOLDBAR_SIGN_IDENTITY" != 'Developer ID Application:'* ]]; then
    echo 'Release signing requires a Developer ID Application certificate.' >&2
    exit 1
fi
notary_auth=()
if [[ -n "${FOLDBAR_NOTARY_PROFILE:-}" ]]; then
    notary_auth=(--keychain-profile "$FOLDBAR_NOTARY_PROFILE")
else
    : "${ASC_API_KEY_ID:?Set ASC_API_KEY_ID or FOLDBAR_NOTARY_PROFILE}"
    : "${ASC_API_ISSUER_ID:?Set ASC_API_ISSUER_ID or FOLDBAR_NOTARY_PROFILE}"
    : "${ASC_API_KEY_PATH:?Set the path to the .p8 key; never commit the key}"
    [[ -f "$ASC_API_KEY_PATH" ]] || { echo 'API key file not found.' >&2; exit 1; }
    notary_auth=(--key "$ASC_API_KEY_PATH" --key-id "$ASC_API_KEY_ID" --issuer "$ASC_API_ISSUER_ID")
fi
version=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Info.plist)
name="FoldBar-${version}-arm64"
output="$PWD/dist/$version"
mkdir -p "$output" build/notarization
export FOLDBAR_RELEASE=1
./test.sh
./build.sh
app="$PWD/build/FoldBar.app"
codesign --verify --deep --strict "$app"

notarize() {
    local file="$1" label="$2" result="$PWD/build/notarization/$version-$2.json"
    echo "Submitting $label to Apple…"
    xcrun notarytool submit "$file" "${notary_auth[@]}" --wait --timeout 20m --output-format json > "$result"
    python3 - "$result" <<'PY'
import json, sys
result = json.load(open(sys.argv[1]))
print('Notarization:', result.get('status'), 'submission:', result.get('id'))
if result.get('status') != 'Accepted':
    raise SystemExit('Notarization not accepted; inspect the submission log before publishing.')
PY
}
staple() {
    local file="$1"
    for attempt in 1 2 3 4 5; do
        if xcrun stapler staple "$file"; then
            xcrun stapler validate "$file"
            return
        fi
        sleep 10
    done
    echo "Could not staple $file" >&2
    return 1
}

# Staple the app before making distributable ZIP/DMG containers.
ditto -c -k --sequesterRsrc --keepParent "$app" "build/notarization/$name.zip"
notarize "build/notarization/$name.zip" app
staple "$app"
spctl --assess --type execute --verbose=4 "$app"

stage=$(mktemp -d "$PWD/build/release-stage.XXXXXX")
trap 'rm -rf "$stage"' EXIT
ditto "$app" "$stage/FoldBar.app"
ln -s /Applications "$stage/Applications"
cp LICENSE "$stage/LICENSE.txt"
printf 'Drag FoldBar into Applications, then open it there.\nRequires macOS 27 and Apple Silicon.\nAllow Accessibility permission when prompted.\nSource: https://github.com/william-jin-cmu/FoldBar\n' > "$stage/Install.txt"
hdiutil create -volname FoldBar -srcfolder "$stage" -ov -format UDZO "$output/$name.dmg"
codesign --force --sign "$FOLDBAR_SIGN_IDENTITY" --timestamp "$output/$name.dmg"
notarize "$output/$name.dmg" dmg
staple "$output/$name.dmg"
codesign --verify --strict "$output/$name.dmg"
spctl --assess --type open --context context:primary-signature --verbose=4 "$output/$name.dmg"
ditto -c -k --sequesterRsrc --keepParent "$app" "$output/$name.zip"

{
    printf 'FoldBar %s — Apple Silicon / macOS 27\n\n' "$version"
    codesign --display --verbose=2 "$app" 2>&1
    spctl --assess --type execute --verbose=4 "$app" 2>&1
    xcrun stapler validate "$app"
    spctl --assess --type open --context context:primary-signature --verbose=4 "$output/$name.dmg" 2>&1
    xcrun stapler validate "$output/$name.dmg"
    printf '\nApple notarization results:\n'
    cat "build/notarization/$version-app.json" "build/notarization/$version-dmg.json"
} > "$output/VERIFICATION.txt"
# Remove local directory prefixes from public verification output.
python3 - "$output/VERIFICATION.txt" "$PWD/" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1]); p.write_text(p.read_text().replace(sys.argv[2], ''))
PY
(cd "$output" && shasum -a 256 "$name.dmg" "$name.zip" VERIFICATION.txt > SHA256SUMS.txt)
printf '\nReady for release: %s\n' "$output"
