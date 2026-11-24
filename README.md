# Window Snapper

A keyboard-first window snapper for macOS, replacing Spectacle. Menu bar only.
Spectacle's default shortcuts; pressing a half again cycles ½ → ⅔ → ⅓.

Design, decisions and research live in the Brain:
`~/Development/Brain/Projects/Personal/window-snapper/`.

## Build

Needs only the Xcode Command Line Tools (Swift 6), not Xcode.

```bash
./scripts/build-app.sh
open "build/Window Snapper.app"
```

Then allow it in System Settings → Privacy & Security → Accessibility.
Quit Spectacle first, since it listens for the same shortcuts.

**After every rebuild** the app has a new ad-hoc signature, so macOS no longer
trusts it even though the switch still looks on. Remove it from the
Accessibility list (−) and add it again. Signing with a stable certificate
fixes this.

## Layout

- `SnapAction.swift`: every action, its shortcut, its maths and its glyph
- `WindowMover.swift`: the Accessibility calls, cycling, restore and displays
- `HotKeys.swift`: global shortcuts through Carbon `RegisterEventHotKey`
- `AppDelegate.swift`: the menu bar item and menu
