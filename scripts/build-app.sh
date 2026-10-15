#!/usr/bin/env bash
# Builds "build/Window Pin.app".
# Calls swiftc directly instead of `swift build`, so it still works when the Command Line
# Tools' package manager is broken ("Invalid manifest" / PackageDescription link errors).
set -euo pipefail
cd "$(dirname "$0")/.."

APP="build/Window Pin.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"

swiftc -O \
    -framework AppKit \
    -framework ApplicationServices \
    -framework Carbon \
    -framework ScreenCaptureKit \
    Sources/WindowPin/*.swift \
    -o "$APP/Contents/MacOS/WindowPin"

cp Resources/Info.plist "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"

echo "Built $APP"
