#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
export SDKROOT="$(xcode-select -p)/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"
mkdir -p build
xcrun swiftc -target "$(uname -m)-apple-macos14.0" Sources/Boundary.swift Tests/main.swift -o build/boundary-tests
./build/boundary-tests
