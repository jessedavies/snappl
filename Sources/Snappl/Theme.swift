import AppKit
import SwiftUI

/// Light: the gallery by day. Dark: the gallery after hours: the painting
/// dimmed under a dark wash, smoky glass, off-white ink. Every colour resolves
/// against the view's own appearance, so a window follows the system or the
/// Appearance setting without any view code knowing which it is.
enum Theme {
    // Ink: text, glyphs, outlines
    static let ink = dynamic(light: rgb(29, 35, 43), dark: rgb(232, 235, 239))
    static let secondary = dynamic(light: rgb(57, 65, 75), dark: rgb(189, 196, 205))
    static let muted = dynamic(light: rgb(72, 81, 92), dark: rgb(149, 158, 170))
    /// The pop-up's mini-display fill: ink at 88%, flattened so guides don't show through.
    static let inkFill = dynamic(light: rgb(56, 61, 68), dark: rgb(223, 227, 232))
    static let inkSolid = dynamic(light: rgb(29, 35, 43, 0.88), dark: rgb(232, 235, 239, 0.9))
    /// Switch track when on. Dark uses slate so the system's white knob still shows.
    static let switchTint = dynamic(light: rgb(29, 35, 43), dark: rgb(122, 138, 160))

    // Glass and what sits on it
    static let glass = dynamic(light: rgb(255, 255, 255, 0.32), dark: rgb(18, 21, 27, 0.55))   // dark: denser smoke, so cards hold against the painting
    static let glassSnapshot = dynamic(light: rgb(255, 255, 255, 0.62), dark: rgb(26, 30, 37, 0.84))
    static let glassEdge = dynamic(light: rgb(255, 255, 255, 0.65), dark: rgb(255, 255, 255, 0.1))
    /// The glass edge as a top-lit gradient. Light: an even white hairline.
    /// Dark: elevation comes from light, so a bright rim on top fading out below.
    static let glassEdgeTop = dynamic(light: rgb(255, 255, 255, 0.65), dark: rgb(255, 255, 255, 0.24))
    static let glassEdgeBottom = dynamic(light: rgb(255, 255, 255, 0.65), dark: rgb(255, 255, 255, 0.04))
    /// Light: two soft ink shadows. Dark: a tight black shadow for separation,
    /// and the wide one turns into a faint light glow (shadows vanish on dark).
    static let shadowNear = dynamic(light: rgb(29, 35, 43, 0.07), dark: rgb(0, 0, 0, 0.32))
    static let shadowFar = dynamic(light: rgb(29, 35, 43, 0.08), dark: rgb(255, 255, 255, 0.035))
    static let keycap = dynamic(light: rgb(255, 255, 255, 0.72), dark: rgb(255, 255, 255, 0.1))
    static let field = dynamic(light: rgb(255, 255, 255, 0.9), dark: rgb(255, 255, 255, 0.08))
    static let tabSelected = dynamic(light: rgb(255, 255, 255, 0.92), dark: rgb(255, 255, 255, 0.16))
    static let popupTint = dynamic(light: rgb(255, 255, 255, 0.28), dark: rgb(24, 28, 35, 0.45))

    // The painting
    static let ground = dynamic(light: rgb(230, 220, 203), dark: rgb(40, 38, 36))
    static let wash = dynamic(light: rgb(255, 255, 255, 0.2), dark: rgb(12, 15, 21, 0.5))
    static let blobMist = dynamic(light: rgb(120, 165, 215, 0.55), dark: rgb(90, 135, 190, 0.32))
    static let blobRose = dynamic(light: rgb(232, 160, 150, 0.5), dark: rgb(190, 115, 105, 0.26))
    static let blobStraw = dynamic(light: rgb(226, 204, 140, 0.5), dark: rgb(190, 165, 95, 0.22))

    private static func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
        NSColor(srgbRed: r / 255, green: g / 255, blue: b / 255, alpha: a)
    }

    private static func dynamic(light: NSColor, dark: NSColor) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
        })
    }
}

/// The Appearance setting: follow macOS, or pin one.
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    /// nil means inherit the system's appearance.
    var nsAppearance: NSAppearance? {
        switch self {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }
}
