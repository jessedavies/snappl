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

## Releasing

1. Bump `CFBundleShortVersionString` (and `CFBundleVersion`) in `Resources/Info.plist`.
2. Run `./scripts/release.sh`. It builds the app, stages it with an Applications shortcut and the painted background (`Resources/DMG/background.tiff`), has Finder lay out the window (macOS asks once to let your terminal control Finder), and writes `dist/Snappl-<version>.dmg`.
3. Publish: `gh release create v<version> dist/Snappl-<version>.dmg --title "Snappl <version>" --notes "…"`.

The background is drawn in `Resources/DMG/background.html` (640 × 400, icons at x 170 and 470, y 200). To change it, edit the page, render it at 1x and 2x with headless Chrome, and combine the two PNGs with `tiffutil -cathidpicheck bg-1.png bg-2.png -out Resources/DMG/background.tiff`.

Releases are signed with the self-signed certificate, not by Apple, so Gatekeeper rejects them until the user clicks Open Anyway once. The stable signature still matters: Accessibility stays granted across updates.

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

## Design library

`library/` is the exploded view of the app: colours, type, paintings, every component in every state, motion, and the screens with demo state, plus PNGs the app renders of itself (`library/render.sh`). It's a static web page, not part of the app:

```bash
python3 -m http.server 8791 -d library
```

Then open http://localhost:8791. Each piece is an HTML rendition of a SwiftUI view; its inspector names the Swift file and view it stands for. Keep them in step: change the rendition when the view changes.

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
