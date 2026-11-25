import AppKit
import ApplicationServices
import Combine
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let mover = WindowMover()
    private let prefs = Preferences.shared
    private lazy var popup = SnapPopup()
    private lazy var settings = SettingsWindowController(recorder: recorder)
    private lazy var onboarding = OnboardingWindowController { [weak self] step in self?.showDemoPopup(step: step) }
    private lazy var recorder = ShortcutRecorder { [weak self] recording in
        // Global shortcuts would swallow the keys being recorded, so they are
        // switched off while the recorder listens.
        self?.shortcutsPaused = recording
        self?.applyShortcuts()
    }
    private var statusItem: NSStatusItem!
    private var takenShortcuts: [SnapAction] = []
    private var shortcutsPaused = false
    private var cancellables: Set<AnyCancellable> = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let i = CommandLine.arguments.firstIndex(of: "--render-popup"), i + 1 < CommandLine.arguments.count {
            PopupSnapshots.write(to: URL(fileURLWithPath: CommandLine.arguments[i + 1]))
            NSApp.terminate(nil)
            return
        }
        if let i = CommandLine.arguments.firstIndex(of: "--render-settings"), i + 1 < CommandLine.arguments.count {
            SettingsSnapshots.write(to: URL(fileURLWithPath: CommandLine.arguments[i + 1]), recorder: recorder) {
                NSApp.terminate(nil)
            }
            return
        }
        if let i = CommandLine.arguments.firstIndex(of: "--render-onboarding"), i + 1 < CommandLine.arguments.count {
            OnboardingSnapshots.write(to: URL(fileURLWithPath: CommandLine.arguments[i + 1])) {
                NSApp.terminate(nil)
            }
            return
        }
        // Render modes exit before this, so they never add a menu bar icon.
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = SnapAction.leftHalf.glyph
        statusItem.button?.setAccessibilityLabel("Snappl")

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        if CommandLine.arguments.contains("--demo-popup") {
            runPopupDemo()
            return
        }

        prefs.$shortcuts
            .dropFirst()
            .receive(on: RunLoop.main) // after the new value is stored
            .sink { [weak self] _ in self?.applyShortcuts() }
            .store(in: &cancellables)
        applyShortcuts()
        // First run: on first launch, and whenever the permission is missing.
        if !OnboardingWindowController.hasFinished || !AXIsProcessTrusted() || CommandLine.arguments.contains("--onboarding") {
            onboarding.show()
        }
        if CommandLine.arguments.contains("--settings") { openSettings() }
    }

    /// Opening the app again (from Finder or Spotlight) shows Settings, since
    /// there is no other window.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        openSettings()
        return false
    }

    // MARK: Shortcuts

    private func applyShortcuts() {
        HotKeyCenter.shared.unregisterAll()
        takenShortcuts = []
        guard !shortcutsPaused else { return }
        for (action, shortcut) in prefs.shortcuts {
            let ok = HotKeyCenter.shared.register(keyCode: shortcut.keyCode, modifiers: shortcut.carbonModifiers) { [weak self] in
                self?.snap(action)
            }
            if !ok { takenShortcuts.append(action) }
        }
        if !takenShortcuts.isEmpty {
            NSLog("Snappl: shortcuts already taken: \(takenShortcuts.map(\.title))")
        }
    }

    private func snap(_ action: SnapAction) {
        // In first run's "Now try it", the shortcut drives the demo instead.
        if action == .leftHalf, onboarding.isTakingShortcuts {
            onboarding.demoPress()
            return
        }
        if let result = mover.perform(action), prefs.showPopup {
            popup.show(result)
        }
    }

    /// The real pop-up for first run's demo, as if the left half had snapped.
    private func showDemoPopup(step: Int) {
        guard prefs.showPopup, let screen = NSScreen.main else { return }
        let area = WindowMover.visibleArea(of: screen)
        let frame = SnapAction.leftHalf.frame(in: area, step: step, current: area)
        popup.show(.init(action: .leftHalf, step: step, frame: frame, area: area))
    }

    /// Steps the pop-up through a left-half cycle on the main screen, with no
    /// window and no permission needed. For working on the pop-up's design.
    private func runPopupDemo() {
        guard let screen = NSScreen.main else { return }
        popup.holdOpen = true
        let area = WindowMover.visibleArea(of: screen)
        for step in 0..<4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Double(step) * 1.5) { [self] in
                let s = step % SnapAction.cycle.count
                let frame = SnapAction.leftHalf.frame(in: area, step: s, current: area)
                popup.show(.init(action: .leftHalf, step: s, frame: frame, area: area))
            }
        }
    }

    // MARK: Accessibility

    @objc private func openOnboarding() {
        onboarding.show()
    }

    // MARK: Menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        if !AXIsProcessTrusted() {
            let item = NSMenuItem(title: "Allow Snappl in Accessibility…", action: #selector(openOnboarding), keyEquivalent: "")
            item.target = self
            menu.addItem(item)
            menu.addItem(.separator())
        }
        if !takenShortcuts.isEmpty {
            let item = NSMenuItem(title: "Some shortcuts are taken by another app", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
            menu.addItem(.separator())
        }

        for (i, section) in SnapAction.sections.enumerated() {
            if i > 0 { menu.addItem(.separator()) }
            for action in section {
                let shortcut = prefs.shortcuts[action]
                let item = NSMenuItem(title: action.title, action: #selector(snapFromMenu(_:)), keyEquivalent: shortcut?.keyEquivalent ?? "")
                item.keyEquivalentModifierMask = shortcut?.modifiers ?? []
                item.image = action.glyph
                item.representedObject = action
                item.target = self
                menu.addItem(item)
            }
        }

        menu.addItem(.separator())
        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(NSMenuItem(title: "Quit Snappl", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    @objc private func snapFromMenu(_ sender: NSMenuItem) {
        guard let action = sender.representedObject as? SnapAction else { return }
        snap(action)
    }

    @objc private func openSettings() {
        settings.show()
    }
}
