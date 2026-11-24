import AppKit
import ApplicationServices

/// Moves the frontmost window with the Accessibility API.
///
/// Coordinates: Accessibility uses a top-left origin with y growing down,
/// measured from the primary display. NSScreen uses a bottom-left origin with
/// y growing up. Everything here is kept in Accessibility coordinates and
/// screens are converted on the way in.
final class WindowMover {
    /// What we last did, so a repeat press on the same window can cycle.
    private var lastAction: SnapAction?
    private var lastWindow: AXUIElement?
    private var lastFrame: CGRect?
    private var step = 0

    /// Frames from before a window was first snapped, for Restore.
    private var originals: [(window: AXUIElement, frame: CGRect)] = []

    /// What a snap did, for the pop-up.
    struct Result {
        let action: SnapAction
        let step: Int
        /// The window's frame after the move, and the usable area of its screen,
        /// both in Accessibility coordinates.
        let frame: CGRect
        let area: CGRect
    }

    @discardableResult
    func perform(_ action: SnapAction) -> Result? {
        guard AXIsProcessTrusted(),
              let (app, window) = focusedWindow(),
              let current = frame(of: window)
        else { NSSound.beep(); return nil }

        let repeating = action == lastAction
            && lastWindow.map { CFEqual($0, window) } == true
            && lastFrame.map { current.isClose(to: $0) } == true
        step = (repeating && action.cycles) ? step + 1 : 0

        let target: CGRect
        switch action {
        case .restore:
            guard let index = originals.firstIndex(where: { CFEqual($0.window, window) }) else { NSSound.beep(); return nil }
            target = originals.remove(at: index).frame
        case .nextDisplay, .previousDisplay:
            guard let moved = frameOnOtherDisplay(current, forward: action == .nextDisplay) else { NSSound.beep(); return nil }
            rememberOriginal(window, current)
            target = moved
        default:
            let area = Self.visibleArea(of: Self.screen(containing: current))
            rememberOriginal(window, current)
            target = action.frame(in: area, step: step, current: current)
        }

        setFrame(target, of: window, in: app)
        lastAction = action
        lastWindow = window
        let landed = frame(of: window) ?? target // read back: some apps round to their own grid
        lastFrame = landed
        return Result(action: action, step: step, frame: landed,
                      area: Self.visibleArea(of: Self.screen(containing: landed)))
    }

    // MARK: Restore bookkeeping

    private func rememberOriginal(_ window: AXUIElement, _ frame: CGRect) {
        // Only the first snap counts; later snaps keep the pre-snap frame.
        guard !originals.contains(where: { CFEqual($0.window, window) }) else { return }
        originals.append((window, frame))
        if originals.count > 50 { originals.removeFirst() }
    }

    // MARK: Accessibility

    private func focusedWindow() -> (AXUIElement, AXUIElement)? {
        guard let front = NSWorkspace.shared.frontmostApplication,
              front.processIdentifier != ProcessInfo.processInfo.processIdentifier
        else { return nil }
        let app = AXUIElementCreateApplication(front.processIdentifier)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute as CFString, &value) == .success,
              let value, CFGetTypeID(value) == AXUIElementGetTypeID()
        else { return nil }
        return (app, value as! AXUIElement)
    }

    private func frame(of window: AXUIElement) -> CGRect? {
        var pos: CFTypeRef?, size: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &pos) == .success,
              AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &size) == .success
        else { return nil }
        var point = CGPoint.zero, extent = CGSize.zero
        AXValueGetValue(pos as! AXValue, .cgPoint, &point)
        AXValueGetValue(size as! AXValue, .cgSize, &extent)
        return CGRect(origin: point, size: extent)
    }

    private func setFrame(_ rect: CGRect, of window: AXUIElement, in app: AXUIElement) {
        // Apps with AXEnhancedUserInterface on (often set by VoiceOver-aware
        // tools) animate and drop size changes. Switch it off while we move.
        let enhanced = "AXEnhancedUserInterface" as CFString // no public constant
        var was: CFTypeRef?
        let hadEnhanced = AXUIElementCopyAttributeValue(app, enhanced, &was) == .success && (was as? Bool) == true
        if hadEnhanced { AXUIElementSetAttributeValue(app, enhanced, kCFBooleanFalse) }

        var origin = rect.origin, size = rect.size
        let posValue = AXValueCreate(.cgPoint, &origin)!
        let sizeValue = AXValueCreate(.cgSize, &size)!
        // Size, move, size again: a window can't grow past the screen edge at
        // its old position, so the second resize lands the full size.
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posValue)
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)

        if hadEnhanced { AXUIElementSetAttributeValue(app, enhanced, kCFBooleanTrue) }
    }

    // MARK: Screens

    private static var primaryHeight: CGFloat { NSScreen.screens.first?.frame.maxY ?? 0 }

    /// NSScreen rect → Accessibility rect.
    static func toAX(_ r: NSRect) -> CGRect {
        CGRect(x: r.minX, y: primaryHeight - r.maxY, width: r.width, height: r.height)
    }

    /// The usable area of a screen (no menu bar, no Dock) in Accessibility coordinates.
    static func visibleArea(of screen: NSScreen) -> CGRect { toAX(screen.visibleFrame) }

    /// The screen holding most of the window.
    static func screen(containing window: CGRect) -> NSScreen {
        NSScreen.screens.max { a, b in
            toAX(a.frame).intersection(window).area < toAX(b.frame).intersection(window).area
        } ?? NSScreen.main ?? NSScreen.screens[0]
    }

    /// Same relative position and proportion on the next (or previous) display,
    /// ordered left to right.
    private func frameOnOtherDisplay(_ current: CGRect, forward: Bool) -> CGRect? {
        let screens = NSScreen.screens.sorted { $0.frame.minX < $1.frame.minX }
        guard screens.count > 1,
              let index = screens.firstIndex(of: Self.screen(containing: current))
        else { return nil }
        let destination = screens[(index + (forward ? 1 : -1) + screens.count) % screens.count]
        let from = Self.visibleArea(of: screens[index])
        let to = Self.visibleArea(of: destination)
        let sx = to.width / from.width, sy = to.height / from.height
        let r = CGRect(x: to.minX + (current.minX - from.minX) * sx,
                       y: to.minY + (current.minY - from.minY) * sy,
                       width: min(current.width * sx, to.width),
                       height: min(current.height * sy, to.height))
        return r.integral
    }
}

private extension CGRect {
    var area: CGFloat { isNull ? 0 : width * height }

    func isClose(to other: CGRect, tolerance: CGFloat = 2) -> Bool {
        abs(minX - other.minX) <= tolerance && abs(minY - other.minY) <= tolerance
            && abs(width - other.width) <= tolerance && abs(height - other.height) <= tolerance
    }
}
