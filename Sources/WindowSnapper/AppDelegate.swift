import AppKit
import ApplicationServices
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let mover = WindowMover()
    private var statusItem: NSStatusItem!
    private var takenShortcuts: [SnapAction] = []
    private var trustTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = SnapAction.leftHalf.glyph
        statusItem.button?.setAccessibilityLabel("Window Snapper")

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        registerShortcuts()
        askForAccessibilityIfNeeded()
    }

    // MARK: Shortcuts

    private func registerShortcuts() {
        takenShortcuts = SnapAction.allCases.filter { action in
            let s = action.shortcut
            let ok = HotKeyCenter.shared.register(keyCode: s.key.carbonKeyCode, modifiers: s.modifiers.carbonModifiers) { [weak self] in
                self?.mover.perform(action)
            }
            return !ok
        }
        if !takenShortcuts.isEmpty {
            NSLog("Window Snapper: shortcuts already taken: \(takenShortcuts.map(\.title))")
        }
    }

    // MARK: Accessibility

    private func askForAccessibilityIfNeeded() {
        guard !AXIsProcessTrusted() else { return }
        let prompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        AXIsProcessTrustedWithOptions([prompt: true] as CFDictionary)
        // Watch for the grant so the menu updates without a relaunch.
        trustTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            if AXIsProcessTrusted() {
                timer.invalidate()
                self?.trustTimer = nil
            }
        }
    }

    @objc private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    // MARK: Menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        if !AXIsProcessTrusted() {
            let item = NSMenuItem(title: "Allow Window Snapper in Accessibility…", action: #selector(openAccessibilitySettings), keyEquivalent: "")
            item.target = self
            menu.addItem(item)
            menu.addItem(.separator())
        }
        if !takenShortcuts.isEmpty {
            let item = NSMenuItem(title: "Some shortcuts are taken. Quit Spectacle and relaunch.", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
            menu.addItem(.separator())
        }

        for (i, section) in SnapAction.sections.enumerated() {
            if i > 0 { menu.addItem(.separator()) }
            for action in section {
                let item = NSMenuItem(title: action.title, action: #selector(snapFromMenu(_:)), keyEquivalent: action.shortcut.key.keyEquivalent)
                item.keyEquivalentModifierMask = action.shortcut.modifiers
                item.image = action.glyph
                item.representedObject = action
                item.target = self
                menu.addItem(item)
            }
        }

        menu.addItem(.separator())
        let login = NSMenuItem(title: "Open at Login", action: #selector(toggleOpenAtLogin), keyEquivalent: "")
        login.target = self
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)
        menu.addItem(NSMenuItem(title: "Quit Window Snapper", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    @objc private func snapFromMenu(_ sender: NSMenuItem) {
        guard let action = sender.representedObject as? SnapAction else { return }
        mover.perform(action)
    }

    @objc private func toggleOpenAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("Window Snapper: open at login failed: \(error)")
            NSSound.beep()
        }
    }
}
