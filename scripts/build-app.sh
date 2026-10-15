#!/usr/bin/env bash
# Builds "build/Window Pin.app" from the Swift package.
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release

APP="build/Window Pin.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp ".build/release/WindowPin" "$APP/Contents/MacOS/WindowPin"
cp Resources/Info.plist "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"

echo "Built $APP"
