#!/bin/zsh
# Builds dist/Snappl-<version>.dmg: the app, an Applications shortcut and the
# painted install-window background, laid out by Finder.
# Unsigned by Apple for now (no Developer ID), so downloaders use "Open Anyway"
# once. Finder layout needs this terminal to be allowed to control Finder;
# macOS asks the first time.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Resources/Info.plist)
NAME="Snappl"
DMG="dist/$NAME-$VERSION.dmg"
STAGE="build/dmg"
RW="build/$NAME-rw.dmg"

./scripts/build-app.sh

rm -rf "$STAGE" "$RW" "$DMG"
mkdir -p "$STAGE/.background" dist
ditto "build/$NAME.app" "$STAGE/$NAME.app"
ln -s /Applications "$STAGE/Applications"
cp Resources/DMG/background.tiff "$STAGE/.background/background.tiff"

hdiutil create -quiet -srcfolder "$STAGE" -volname "$NAME" -fs HFS+ -format UDRW -size 60m "$RW"
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "$RW" | awk '/Apple_HFS/ {print $1}')
sleep 1

# Window 640 x 400 of content (Finder adds the title bar), icons at the
# positions the background was drawn for.
osascript <<OSA
tell application "Finder"
  tell disk "$NAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set bounds of container window to {200, 120, 840, 548}
    set opts to the icon view options of container window
    set arrangement of opts to not arranged
    set icon size of opts to 128
    set text size of opts to 13
    set background picture of opts to file ".background:background.tiff"
    set position of item "$NAME.app" of container window to {170, 200}
    set position of item "Applications" of container window to {470, 200}
    update without registering applications
    delay 1
    close
  end tell
end tell
OSA

chmod -Rf go-w "/Volumes/$NAME" || true
sync
hdiutil detach -quiet "$DEVICE"
hdiutil convert -quiet "$RW" -format UDZO -imagekey zlib-level=9 -o "$DMG"
rm -f "$RW"
echo "Built $DMG ($(du -h "$DMG" | cut -f1))"
