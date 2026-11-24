import AppKit
import Carbon

/// A key plus modifiers, saved as plain values so it can live in UserDefaults.
struct Shortcut: Codable, Equatable {
    let keyCode: UInt32
    let modifierRaw: UInt
    /// What the key shows on its keycap ("←", "F", "F5").
    let key: String

    init(keyCode: Int, modifiers: NSEvent.ModifierFlags, key: String) {
        self.keyCode = UInt32(keyCode)
        self.modifierRaw = modifiers.intersection(Self.relevant).rawValue
        self.key = key
    }

    /// From a key press in the recorder. Nil when the key can't be named.
    init?(event: NSEvent) {
        guard let key = Self.name(for: event) else { return nil }
        self.init(keyCode: Int(event.keyCode), modifiers: event.modifierFlags, key: key)
    }

    static let relevant: NSEvent.ModifierFlags = [.control, .option, .shift, .command]

    var modifiers: NSEvent.ModifierFlags { NSEvent.ModifierFlags(rawValue: modifierRaw) }

    var carbonModifiers: UInt32 {
        var m = 0
        if modifiers.contains(.command) { m |= cmdKey }
        if modifiers.contains(.option) { m |= optionKey }
        if modifiers.contains(.control) { m |= controlKey }
        if modifiers.contains(.shift) { m |= shiftKey }
        return UInt32(m)
    }

    /// One keycap per modifier, in Apple's order, then the key.
    var caps: [String] {
        var c: [String] = []
        if modifiers.contains(.control) { c.append("⌃") }
        if modifiers.contains(.option) { c.append("⌥") }
        if modifiers.contains(.shift) { c.append("⇧") }
        if modifiers.contains(.command) { c.append("⌘") }
        return c + [key]
    }

    var displayString: String { caps.joined() }

    /// For NSMenuItem, which draws the shortcut natively. Empty when the key
    /// has no menu equivalent.
    var keyEquivalent: String {
        switch Int(keyCode) {
        case kVK_LeftArrow: return String(UnicodeScalar(NSLeftArrowFunctionKey)!)
        case kVK_RightArrow: return String(UnicodeScalar(NSRightArrowFunctionKey)!)
        case kVK_UpArrow: return String(UnicodeScalar(NSUpArrowFunctionKey)!)
        case kVK_DownArrow: return String(UnicodeScalar(NSDownArrowFunctionKey)!)
        default: return key.count == 1 ? key.lowercased() : ""
        }
    }

    private static let named: [Int: String] = [
        kVK_LeftArrow: "←", kVK_RightArrow: "→", kVK_UpArrow: "↑", kVK_DownArrow: "↓",
        kVK_Return: "↩", kVK_Tab: "⇥", kVK_Space: "Space", kVK_Delete: "⌫", kVK_ForwardDelete: "⌦",
        kVK_Home: "↖", kVK_End: "↘", kVK_PageUp: "⇞", kVK_PageDown: "⇟",
        kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4", kVK_F5: "F5", kVK_F6: "F6",
        kVK_F7: "F7", kVK_F8: "F8", kVK_F9: "F9", kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12",
    ]

    private static func name(for event: NSEvent) -> String? {
        if let n = named[Int(event.keyCode)] { return n }
        // The key's own character, ignoring modifiers (so ⌥⌘F reads "F", not "ƒ").
        guard let chars = event.characters(byApplyingModifiers: []), !chars.isEmpty,
              chars.unicodeScalars.allSatisfy({ !CharacterSet.controlCharacters.contains($0) })
        else { return nil }
        return chars.uppercased()
    }
}
