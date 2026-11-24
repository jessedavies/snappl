# Developing Snappl

Snappl is a Swift Package built with Apple's Command Line Tools (Swift 6, macOS 13+). There is no Xcode project: `scripts/build-app.sh` wraps the binary in an `.app` bundle.

## Build and run

```bash
./scripts/build-app.sh
```

Builds `build/Snappl.app` without installing it.

```bash
./scripts/install.sh
```

Builds, quits any running Snappl, replaces `/Applications/Snappl.app` and opens it. Run only one copy at a time: two copies register the same shortcuts.

## Signing

macOS ties the Accessibility permission to the app's code signature. With ad hoc signing the signature changes every build, so the permission silently stops working after each rebuild (the switch in System Settings still looks on). Remove Snappl from the list and add it again to fix it.

To avoid that, create a self-signed code-signing certificate named **Local Code Signing** in your login keychain (Keychain Access → Certificate Assistant → Create a Certificate, type Code Signing). `build-app.sh` uses it when it exists and falls back to ad hoc signing when it doesn't. Keychain Access shows it as "not trusted"; that's expected.

Public releases need an Apple Developer ID certificate and notarisation instead, so downloads open without a warning. That isn't set up yet.

## Layout

| Path | What |
| --- | --- |
| `Sources/Snappl/SnapAction.swift` | every action: name, default shortcut, cycle maths, pop-up label, glyph |
| `Sources/Snappl/WindowMover.swift` | the Accessibility calls, cycling, restore and display moves |
| `Sources/Snappl/HotKeys.swift` | global shortcuts through Carbon `RegisterEventHotKey` |
| `Sources/Snappl/Shortcut.swift`, `Preferences.swift` | saved shortcuts and settings (UserDefaults) |
| `Sources/Snappl/ShortcutRecorder.swift` | the shortcut recorder in Settings |
| `Sources/Snappl/SettingsWindow.swift` | the Settings window |
| `Sources/Snappl/SnapPopup.swift` | the snap pop-up |
| `Sources/Snappl/AppDelegate.swift` | the menu bar item, the menu and launch flags |
| `Resources/` | `Info.plist`, the app icon, the paintings |
| `scripts/make-icon.py` | rebuilds `Resources/AppIcon.icns` (needs Pillow) |

Note on coordinates: the Accessibility API measures from the top-left of the primary display, `NSScreen` from the bottom-left. `WindowMover` keeps everything in Accessibility coordinates and converts screens on the way in.

## Working on the design

Run `./scripts/build-app.sh` first; these use `build/Snappl.app/Contents/MacOS/Snappl`. Quit the installed Snappl before using the on-screen ones.

| Flag | What it does |
| --- | --- |
| `--demo-popup` | steps the pop-up through a left-half cycle on screen, no permission needed |
| `--render-popup <folder>` | writes PNGs of the pop-up for several snaps, then exits |
| `--render-settings <folder>` | writes PNGs of Settings (both panes, and recording), then exits |
| `--settings` | opens Settings on launch |

Add `-shortcuts none` to any of them to show the default shortcuts without touching your saved ones.

The visual design (paintings under clear white glass, cool ink, one icon grid, serif only on the painting's caption) is documented in the Snappl design system. The paintings are by Clarice Beckett (1887–1935), public domain; the scans come from Wikimedia Commons.
