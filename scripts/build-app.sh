#!/usr/bin/env bash
# Builds "build/Window Pane Relief.app" and installs it in /Applications.
# Calls swiftc directly instead of `swift build`, so it still works when the Command Line
# Tools' package manager is broken ("Invalid manifest" / PackageDescription link errors).
set -euo pipefail
cd "$(dirname "$0")/.."

APP="build/Window Pane Relief.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"

swiftc -O \
    -framework AppKit \
    -framework ApplicationServices \
    -framework Carbon \
    -framework ScreenCaptureKit \
    Sources/WindowPin/*.swift \
    -o "$APP/Contents/MacOS/WindowPaneRelief"

cp Resources/Info.plist "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"

echo "Built $APP"

# Replace any installed copy, quitting it first if it's running.
pkill -x WindowPaneRelief 2>/dev/null && sleep 1 || true
pkill -x WindowPin 2>/dev/null && sleep 1 || true   # its name before Window Pane Relief
rm -rf "/Applications/Window Pin.app"
rm -rf "/Applications/Window Pane Relief.app"
cp -R "$APP" /Applications/
echo "Installed /Applications/Window Pane Relief.app"

open "/Applications/Window Pane Relief.app"
