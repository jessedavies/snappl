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
- `AppDelegate.swift`: the menu bar item and menu, and applying shortcuts
- `Shortcut.swift`, `Preferences.swift`: saved shortcuts and settings (UserDefaults)
- `SettingsWindow.swift`, `ShortcutRecorder.swift`: the painted Settings window and its recorder
- `SnapPopup.swift`: the glass pop-up

## Working on the snap pop-up

- `"build/Window Snapper.app/Contents/MacOS/WindowSnapper" --demo-popup` steps the pop-up through a left-half cycle on screen, with no window or permission needed. Quit it from the menu bar afterwards.
- `... --render-popup <folder>` writes PNGs of the pop-up content for several snaps and exits.
- `... --render-settings <folder>` writes PNGs of Settings (both tabs, and recording) and exits.
- `... --settings` launches with Settings open.

The Settings painting is Clarice Beckett's *Sunny Day* (Beckett died 1935; public domain in Australia), from Wikimedia Commons at 650 px, which is soft at Retina size.
