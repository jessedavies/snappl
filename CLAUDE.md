# Snappl — Claude instructions

macOS menu-bar window snapper (Swift Package, Command Line Tools, no Xcode). Brain docs: `~/Development/Brain/Projects/Personal/snappl/`.

- Build `./scripts/build-app.sh`; install `./scripts/install.sh`; release DMG `./scripts/release.sh`. Run one copy of the app at a time (`pkill -x Snappl` before launching a test build), and never launch after a build whose output was piped through grep.
- **Library (exploded view):** `library/` is the WIP design library: every piece of the app redrawn in HTML with its states, the real file and view named for each, live demo screens and the app's own renders. Serve it with `python3 -m http.server 8791 -d library` (preview config `snappl-library`). **When you add or change a view, update its spec in `library/index.html` and its rendition in `library/pieces.js` in the same change**, and refresh the app renders with `library/render.sh`.
- First run (`Onboarding.swift`) opens on first launch and whenever Accessibility is missing; finishing it sets `hasFinishedFirstRun`. While it's in front, ⌥⌘← drives its demo instead of snapping.
- Debug flags: `--render-popup <dir>`, `--render-settings <dir>`, `--render-onboarding <dir>`, `--demo-popup`, `--settings`, `--onboarding`; add `-shortcuts none` to show default shortcuts without touching saved ones.
