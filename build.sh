#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
SDK="$(xcode-select -p)/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"
if [[ ! -d "$SDK" ]]; then SDK="$(xcrun --sdk macosx --show-sdk-path)"; fi
export SDKROOT="$SDK"
mkdir -p build/FoldBar.app/Contents/MacOS
xcrun clang -isysroot "$SDK" -mmacosx-version-min=14.0 -fobjc-arc -fmodules -c Sources/Bridge.m -o build/Bridge.o
xcrun swiftc -sdk "$SDK" -target arm64-apple-macos14.0 -swift-version 5 -O -import-objc-header Sources/Bridge.h Sources/Boundary.swift Sources/MenuSnapshot.swift Sources/SmokeTest.swift Sources/Preferences.swift Sources/Settings.swift Sources/Shortcut.swift Sources/main.swift build/Bridge.o -o build/FoldBar.app/Contents/MacOS/FoldBar -framework AppKit -framework ApplicationServices -framework ServiceManagement -framework SwiftUI -framework Carbon
mkdir -p build/FoldBar.app/Contents/Resources build/AppIcon.iconset
for size in 16 32 128 256 512; do
    sips -z "$size" "$size" Assets/FoldBar-logo-v2.png --out "build/AppIcon.iconset/icon_${size}x${size}.png" >/dev/null
    double=$((size * 2))
    sips -z "$double" "$double" Assets/FoldBar-logo-v2.png --out "build/AppIcon.iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns build/AppIcon.iconset -o build/FoldBar.app/Contents/Resources/AppIcon.icns
cp Info.plist build/FoldBar.app/Contents/Info.plist
cp LICENSE NOTICE REFERENCES.md build/FoldBar.app/Contents/Resources/
if [[ "${FOLDBAR_RELEASE:-0}" == 1 && -z "${FOLDBAR_SIGN_IDENTITY:-}" ]]; then
    echo "Release builds require FOLDBAR_SIGN_IDENTITY." >&2
    exit 1
fi
if [[ -n "${FOLDBAR_SIGN_IDENTITY:-}" ]]; then
    timestamp=--timestamp=none
    [[ "${FOLDBAR_RELEASE:-0}" == 1 ]] && timestamp=--timestamp
    codesign --force --sign "$FOLDBAR_SIGN_IDENTITY" --options runtime "$timestamp" build/FoldBar.app
else
    codesign --force --sign - build/FoldBar.app
fi
codesign --verify --strict build/FoldBar.app
printf 'Built: %s/build/FoldBar.app\n' "$PWD"
