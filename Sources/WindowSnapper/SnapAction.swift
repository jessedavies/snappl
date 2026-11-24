import AppKit
import Carbon

/// Every snap, with Spectacle's default shortcut and the glyph used in the menu.
enum SnapAction: CaseIterable {
    case leftHalf, rightHalf, topHalf, bottomHalf
    case topLeft, topRight, bottomLeft, bottomRight
    case maximise, centre
    case nextDisplay, previousDisplay
    case restore

    /// Menu sections, in order.
    static let sections: [[SnapAction]] = [
        [.leftHalf, .rightHalf, .topHalf, .bottomHalf],
        [.topLeft, .topRight, .bottomLeft, .bottomRight],
        [.maximise, .centre],
        [.nextDisplay, .previousDisplay, .restore],
    ]

    var title: String {
        switch self {
        case .leftHalf: "Left Half"
        case .rightHalf: "Right Half"
        case .topHalf: "Top Half"
        case .bottomHalf: "Bottom Half"
        case .topLeft: "Top Left"
        case .topRight: "Top Right"
        case .bottomLeft: "Bottom Left"
        case .bottomRight: "Bottom Right"
        case .maximise: "Maximise"
        case .centre: "Centre"
        case .nextDisplay: "Next Display"
        case .previousDisplay: "Previous Display"
        case .restore: "Restore"
        }
    }

    // MARK: Shortcuts (Spectacle defaults)

    enum Key { case left, right, up, down, f, c, z }

    struct Shortcut {
        let key: Key
        let modifiers: NSEvent.ModifierFlags
    }

    var shortcut: Shortcut {
        let optCmd: NSEvent.ModifierFlags = [.option, .command]
        let ctrlCmd: NSEvent.ModifierFlags = [.control, .command]
        switch self {
        case .leftHalf: return Shortcut(key: .left, modifiers: optCmd)
        case .rightHalf: return Shortcut(key: .right, modifiers: optCmd)
        case .topHalf: return Shortcut(key: .up, modifiers: optCmd)
        case .bottomHalf: return Shortcut(key: .down, modifiers: optCmd)
        case .topLeft: return Shortcut(key: .left, modifiers: ctrlCmd)
        case .topRight: return Shortcut(key: .right, modifiers: ctrlCmd)
        case .bottomLeft: return Shortcut(key: .left, modifiers: [.control, .shift, .command])
        case .bottomRight: return Shortcut(key: .right, modifiers: [.control, .shift, .command])
        case .maximise: return Shortcut(key: .f, modifiers: optCmd)
        case .centre: return Shortcut(key: .c, modifiers: optCmd)
        case .nextDisplay: return Shortcut(key: .right, modifiers: [.control, .option, .command])
        case .previousDisplay: return Shortcut(key: .left, modifiers: [.control, .option, .command])
        case .restore: return Shortcut(key: .z, modifiers: optCmd)
        }
    }

    // MARK: Cycling

    /// Repeat presses step through these fractions: ½ → ⅔ → ⅓.
    static let cycle: [CGFloat] = [1.0 / 2.0, 2.0 / 3.0, 1.0 / 3.0]

    var cycles: Bool {
        switch self {
        case .leftHalf, .rightHalf, .topHalf, .bottomHalf, .topLeft, .topRight, .bottomLeft, .bottomRight: true
        default: false
        }
    }

    /// The target frame inside `area`, both in Accessibility coordinates
    /// (origin top-left, y grows down). Display moves and restore are handled
    /// by the mover, not here.
    func frame(in area: CGRect, step: Int, current: CGRect) -> CGRect {
        let f = SnapAction.cycle[step % SnapAction.cycle.count]
        let w = (area.width * f).rounded()
        let h = (area.height * f).rounded()
        let halfH = (area.height / 2).rounded()
        switch self {
        case .leftHalf: return CGRect(x: area.minX, y: area.minY, width: w, height: area.height)
        case .rightHalf: return CGRect(x: area.maxX - w, y: area.minY, width: w, height: area.height)
        case .topHalf: return CGRect(x: area.minX, y: area.minY, width: area.width, height: h)
        case .bottomHalf: return CGRect(x: area.minX, y: area.maxY - h, width: area.width, height: h)
        case .topLeft: return CGRect(x: area.minX, y: area.minY, width: w, height: halfH)
        case .topRight: return CGRect(x: area.maxX - w, y: area.minY, width: w, height: halfH)
        case .bottomLeft: return CGRect(x: area.minX, y: area.maxY - halfH, width: w, height: halfH)
        case .bottomRight: return CGRect(x: area.maxX - w, y: area.maxY - halfH, width: w, height: halfH)
        case .maximise: return area
        case .centre:
            let size = CGSize(width: min(current.width, area.width), height: min(current.height, area.height))
            return CGRect(x: (area.midX - size.width / 2).rounded(), y: (area.midY - size.height / 2).rounded(),
                          width: size.width, height: size.height)
        case .nextDisplay, .previousDisplay, .restore:
            return current
        }
    }

    // MARK: Glyph

    /// The filled region of the 16×12 icon, as percentages (left, top, width, height).
    private var glyphRegion: (CGFloat, CGFloat, CGFloat, CGFloat) {
        switch self {
        case .leftHalf: (0, 0, 50, 100)
        case .rightHalf: (50, 0, 50, 100)
        case .topHalf: (0, 0, 100, 50)
        case .bottomHalf: (0, 50, 100, 50)
        case .topLeft: (0, 0, 50, 50)
        case .topRight: (50, 0, 50, 50)
        case .bottomLeft: (0, 50, 50, 50)
        case .bottomRight: (50, 50, 50, 50)
        case .maximise: (0, 0, 100, 100)
        case .centre: (20, 15, 60, 70)
        case .nextDisplay: (60, 0, 40, 100)
        case .previousDisplay: (0, 0, 40, 100)
        case .restore: (28, 22, 44, 56)
        }
    }

    var glyph: NSImage { SnapAction.glyph(glyphRegion) }

    /// One icon grid for the whole app: a 16×12 rounded screen with a solid fill.
    static func glyph(_ r: (CGFloat, CGFloat, CGFloat, CGFloat)) -> NSImage {
        let image = NSImage(size: NSSize(width: 16, height: 12), flipped: true) { _ in
            NSColor.black.set()
            let frame = NSBezierPath(roundedRect: NSRect(x: 0.75, y: 0.75, width: 14.5, height: 10.5), xRadius: 2.5, yRadius: 2.5)
            frame.lineWidth = 1.25
            frame.stroke()
            let fill = NSRect(x: 2.5 + r.0 * 0.11, y: 2.5 + r.1 * 0.07, width: r.2 * 0.11, height: r.3 * 0.07)
            NSBezierPath(roundedRect: fill, xRadius: 1, yRadius: 1).fill()
            return true
        }
        image.isTemplate = true
        return image
    }
}

extension SnapAction.Key {
    var carbonKeyCode: UInt32 {
        switch self {
        case .left: UInt32(kVK_LeftArrow)
        case .right: UInt32(kVK_RightArrow)
        case .up: UInt32(kVK_UpArrow)
        case .down: UInt32(kVK_DownArrow)
        case .f: UInt32(kVK_ANSI_F)
        case .c: UInt32(kVK_ANSI_C)
        case .z: UInt32(kVK_ANSI_Z)
        }
    }

    var keyEquivalent: String {
        switch self {
        case .left: String(UnicodeScalar(NSLeftArrowFunctionKey)!)
        case .right: String(UnicodeScalar(NSRightArrowFunctionKey)!)
        case .up: String(UnicodeScalar(NSUpArrowFunctionKey)!)
        case .down: String(UnicodeScalar(NSDownArrowFunctionKey)!)
        case .f: "f"
        case .c: "c"
        case .z: "z"
        }
    }
}

extension NSEvent.ModifierFlags {
    var carbonModifiers: UInt32 {
        var m = 0
        if contains(.command) { m |= cmdKey }
        if contains(.option) { m |= optionKey }
        if contains(.control) { m |= controlKey }
        if contains(.shift) { m |= shiftKey }
        return UInt32(m)
    }
}
