#!/bin/zsh
# Builds Snappl and installs it to /Applications, replacing any older copy,
# then opens it. Run from anywhere.
set -euo pipefail
cd "$(dirname "$0")/.."
./scripts/build-app.sh
osascript -e 'tell application id "com.jessedavies.snappl" to quit' 2>/dev/null || true
pkill -x Snappl 2>/dev/null || true
sleep 0.5
rm -rf /Applications/Snappl.app
ditto build/Snappl.app /Applications/Snappl.app
# The build copy shares the bundle ID; only the installed one should launch.
rm -rf build/Snappl.app
open /Applications/Snappl.app
echo "Installed /Applications/Snappl.app"
