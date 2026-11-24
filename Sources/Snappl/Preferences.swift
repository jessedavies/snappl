import Combine
import Foundation

/// Everything the user can change, saved in UserDefaults.
final class Preferences: ObservableObject {
    static let shared = Preferences()

    private let defaults = UserDefaults.standard
    private enum Key {
        static let cycle = "cycleSizes"
        static let popup = "showPopup"
        static let shortcuts = "shortcuts"
        static let appearance = "appearance"
    }

    /// Repeat presses step ½ → ⅔ → ⅓.
    @Published var cycleSizes: Bool { didSet { defaults.set(cycleSizes, forKey: Key.cycle) } }

    /// Show the glass pop-up after each snap.
    @Published var showPopup: Bool { didSet { defaults.set(showPopup, forKey: Key.popup) } }

    /// Light, dark, or follow the system (the default).
    @Published var appearance: AppearanceMode { didSet { defaults.set(appearance.rawValue, forKey: Key.appearance) } }

    /// Current shortcuts. An action with no entry has no shortcut.
    @Published private(set) var shortcuts: [SnapAction: Shortcut]

    private init() {
        Self.migrateFromWindowSnapper(into: defaults)
        defaults.register(defaults: [Key.cycle: true, Key.popup: true])
        cycleSizes = defaults.bool(forKey: Key.cycle)
        showPopup = defaults.bool(forKey: Key.popup)
        appearance = defaults.string(forKey: Key.appearance).flatMap(AppearanceMode.init(rawValue:)) ?? .system
        if let data = defaults.data(forKey: Key.shortcuts),
           let saved = try? JSONDecoder().decode([String: Shortcut].self, from: data) {
            shortcuts = Dictionary(uniqueKeysWithValues: saved.compactMap { k, v in SnapAction(rawValue: k).map { ($0, v) } })
        } else {
            shortcuts = SnapAction.spectacleDefaults
        }
    }

    /// Sets (or clears, with nil) one action's shortcut. A shortcut can belong
    /// to one action only, so whichever action had it loses it.
    func setShortcut(_ shortcut: Shortcut?, for action: SnapAction) {
        var next = shortcuts
        if let shortcut {
            for (other, s) in next where s == shortcut && other != action { next[other] = nil }
        }
        next[action] = shortcut
        shortcuts = next
        save()
    }

    func restoreSpectacleDefaults() {
        shortcuts = SnapAction.spectacleDefaults
        save()
    }

    var isUsingDefaults: Bool { shortcuts == SnapAction.spectacleDefaults }

    /// The app was called Window Snapper (com.jessedavies.windowsnapper) until
    /// 2026-11-24. Copy its settings across once, the first time Snappl runs.
    private static func migrateFromWindowSnapper(into defaults: UserDefaults) {
        let done = "migratedFromWindowSnapper"
        guard !defaults.bool(forKey: done) else { return }
        defaults.set(true, forKey: done)
        guard let old = UserDefaults(suiteName: "com.jessedavies.windowsnapper") else { return }
        for key in [Key.cycle, Key.popup, Key.shortcuts] where defaults.object(forKey: key) == nil {
            if let value = old.object(forKey: key) { defaults.set(value, forKey: key) }
        }
    }

    private func save() {
        let plain = Dictionary(uniqueKeysWithValues: shortcuts.map { ($0.key.rawValue, $0.value) })
        if let data = try? JSONEncoder().encode(plain) { defaults.set(data, forKey: Key.shortcuts) }
    }
}
