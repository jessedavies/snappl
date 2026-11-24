#!/bin/zsh
# Builds Snappl.app into ./build. Run from the repo root.
set -euo pipefail
cd "$(dirname "$0")/.."
swift build -c release
APP="build/Snappl.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/Snappl "$APP/Contents/MacOS/Snappl"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/Paintings/*.jpg Resources/AppIcon.icns "$APP/Contents/Resources/"

# Sign with the self-signed "Local Code Signing" certificate in the login
# keychain. A stable signature means macOS keeps the Accessibility grant across
# rebuilds. Without it, fall back to ad hoc and the grant resets every build.
IDENTITY="Local Code Signing"
if security find-identity -p codesigning | grep -q "\"$IDENTITY\""; then
  codesign --force --sign "$IDENTITY" --identifier com.jessedavies.snappl "$APP"
else
  echo "warning: no \"$IDENTITY\" certificate, signing ad hoc" >&2
  codesign --force --sign - --identifier com.jessedavies.snappl "$APP"
fi
echo "Built $APP"
