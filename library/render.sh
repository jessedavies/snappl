#!/bin/zsh
# Refreshes library/renders/ with PNGs drawn by the app itself (the source of
# truth the HTML renditions are checked against). Uses default shortcuts
# without touching saved ones.
set -euo pipefail
cd "$(dirname "$0")/.."
./scripts/build-app.sh > /dev/null
BIN=build/Snappl.app/Contents/MacOS/Snappl
for flag in --render-settings --render-popup --render-onboarding; do
  "$BIN" $flag library/renders -shortcuts none &
  pid=$!
  for i in {1..60}; do kill -0 $pid 2>/dev/null || break; sleep 0.5; done
  kill $pid 2>/dev/null || true
done
ls library/renders
