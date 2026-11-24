# Snappl

A keyboard-first window snapper for macOS (formerly Window Snapper), replacing Spectacle. Menu bar only.
Spectacle's default shortcuts; pressing a half again cycles ½ → ⅔ → ⅓.

Design, decisions and research live in the Brain:
`~/Development/Brain/Projects/Personal/window-snapper/`.

## Install

Needs only the Xcode Command Line Tools (Swift 6), not Xcode.

```bash
./scripts/install.sh
```

Builds, signs, replaces `/Applications/Snappl.app` and opens it. After that it
behaves like any app: Spotlight, Launchpad, and Open at Login in Settings.
`./scripts/build-app.sh` builds to `build/Snappl.app` without installing.

First run only: allow Snappl in System Settings → Privacy & Security →
Accessibility, and quit Spectacle (it listens for the same shortcuts).

### Signing

Builds are signed with a self-signed certificate called **Local Code Signing**
in the login keychain (created 2026-11-24, valid 10 years). Because the
signature is stable, macOS keeps the Accessibility grant across rebuilds.
Keychain Access shows it as "not trusted"; that is expected and doesn't stop
signing. Without it the build script falls back to ad hoc signing and the grant
resets every build. To share Snappl with other people it would need a paid
Apple Developer ID and notarisation instead.

### Icon

`python3 -I scripts/make-icon.py` rebuilds `Resources/AppIcon.icns` from
`Resources/Icon/passing-trams.jpg` (needs Pillow).

## Layout

- `SnapAction.swift`: every action, its shortcut, its maths and its glyph
- `WindowMover.swift`: the Accessibility calls, cycling, restore and displays
- `HotKeys.swift`: global shortcuts through Carbon `RegisterEventHotKey`
- `AppDelegate.swift`: the menu bar item and menu, and applying shortcuts
- `Shortcut.swift`, `Preferences.swift`: saved shortcuts and settings (UserDefaults)
- `SettingsWindow.swift`, `ShortcutRecorder.swift`: the painted Settings window and its recorder
- `SnapPopup.swift`: the glass pop-up

## Working on the snap pop-up

Run `./scripts/build-app.sh` first; these use `build/Snappl.app`.

- `"build/Snappl.app/Contents/MacOS/Snappl" --demo-popup` steps the pop-up through a left-half cycle on screen, with no window or permission needed. It adds a second menu bar icon while it runs; quit it from that icon afterwards.
- `... --render-popup <folder>` writes PNGs of the pop-up content for several snaps and exits.
- `... --render-settings <folder>` writes PNGs of Settings (both tabs, and recording) and exits.
- `... --settings` launches with Settings open.

The Settings painting is Clarice Beckett's *Sunny Day* (Beckett died 1935; public domain in Australia), from Wikimedia Commons at 650 px, which is soft at Retina size.
