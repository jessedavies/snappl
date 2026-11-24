#!/bin/zsh
# Builds Window Snapper.app into ./build. Run from the repo root.
set -euo pipefail
cd "$(dirname "$0")/.."
swift build -c release
APP="build/Window Snapper.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/WindowSnapper "$APP/Contents/MacOS/WindowSnapper"
cp Resources/Info.plist "$APP/Contents/Info.plist"
mkdir -p "$APP/Contents/Resources"
cp Resources/Paintings/*.jpg "$APP/Contents/Resources/"
# Ad-hoc signature. macOS ties the Accessibility grant to it, so each rebuild
# needs the grant redone until we sign with a stable certificate.
codesign --force --sign - --identifier com.jessedavies.windowsnapper "$APP"
echo "Built $APP"
