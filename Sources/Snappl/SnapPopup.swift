import AppKit
import SwiftUI

/// The snap pop-up: a small glass tile in the centre of the screen.
/// It shows a mini display with the window's new region filled in, the name of
/// the snap, and which step of the ½ → ⅔ → ⅓ cycle this is. A repeat press
/// keeps the same tile up and animates the fill to the new size.
final class SnapPopup {
    private let model = PopupModel()
    private let panel: NSPanel
    private let hosting: NSHostingView<PopupView>
    private var hideWork: DispatchWorkItem?
    /// Keeps the tile up (for `--demo-popup`, when designing it).
    var holdOpen = false

    private static let radius: CGFloat = 28
    private static let visibleFor: TimeInterval = 0.9

    init() {
        panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .popUpMenu
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.appearance = NSAppearance(named: .aqua) // the design is light glass

        let glass = NSVisualEffectView()
        glass.material = .popover
        glass.blendingMode = .behindWindow
        glass.state = .active
        glass.maskImage = Self.roundedMask(radius: Self.radius)

        hosting = NSHostingView(rootView: PopupView(model: model))
        hosting.translatesAutoresizingMaskIntoConstraints = false
        glass.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: glass.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: glass.trailingAnchor),
            hosting.topAnchor.constraint(equalTo: glass.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: glass.bottomAnchor),
        ])
        panel.contentView = glass
    }

    func show(_ result: WindowMover.Result) {
        let wasVisible = panel.isVisible && panel.alphaValue > 0.01
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

        // Update the content. SwiftUI animates the fill and dots when the tile
        // is already up; a fresh tile starts in its final state.
        var transaction = Transaction()
        transaction.disablesAnimations = !wasVisible || reduceMotion
        withTransaction(transaction) { model.update(with: result) }

        // Always the centre of the screen the window ended up on. The tile stays
        // put on repeat presses; only its contents change.
        let frame = Self.panelFrame(size: hosting.fittingSize, centredOn: result.area)
        panel.setFrame(frame, display: true)
        if !wasVisible { panel.alphaValue = 0 }
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.14
            panel.animator().alphaValue = 1
        }
        panel.invalidateShadow()
        scheduleHide()
    }

    private func scheduleHide() {
        hideWork?.cancel()
        guard !holdOpen else { return }
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.22
                self.panel.animator().alphaValue = 0
            }, completionHandler: { [weak self] in
                guard let self, self.panel.alphaValue < 0.01 else { return }
                self.panel.orderOut(nil)
            })
        }
        hideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.visibleFor, execute: work)
    }

    /// Centre of the window's new frame, converted to screen coordinates and
    /// kept on its screen.
    private static func panelFrame(size: CGSize, centredOn axFrame: CGRect) -> NSRect {
        let primaryHeight = NSScreen.screens.first?.frame.maxY ?? 0
        let centre = NSPoint(x: axFrame.midX, y: primaryHeight - axFrame.midY)
        var frame = NSRect(x: (centre.x - size.width / 2).rounded(), y: (centre.y - size.height / 2).rounded(),
                           width: size.width, height: size.height)
        if let screen = NSScreen.screens.first(where: { $0.frame.contains(centre) }) {
            let v = screen.visibleFrame.insetBy(dx: 12, dy: 12)
            frame.origin.x = min(max(frame.minX, v.minX), v.maxX - frame.width)
            frame.origin.y = min(max(frame.minY, v.minY), v.maxY - frame.height)
        }
        return frame
    }

    private static func roundedMask(radius: CGFloat) -> NSImage {
        let edge = radius * 2 + 1
        let image = NSImage(size: NSSize(width: edge, height: edge), flipped: false) { rect in
            NSColor.black.set()
            NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
            return true
        }
        image.capInsets = NSEdgeInsets(top: radius, left: radius, bottom: radius, right: radius)
        image.resizingMode = .stretch
        return image
    }
}

// MARK: - Content

final class PopupModel: ObservableObject {
    /// The window's region inside the mini display, as fractions of the screen (0…1).
    @Published var region = CGRect(x: 0, y: 0, width: 0.5, height: 1)
    @Published var label = ""
    @Published var axis: SnapAction.CycleAxis = .none
    @Published var step = 0

    func update(with r: WindowMover.Result) {
        let a = r.area
        let clipped = r.frame.intersection(a)
        let f = clipped.isNull ? r.frame : clipped
        region = CGRect(x: (f.minX - a.minX) / a.width, y: (f.minY - a.minY) / a.height,
                        width: f.width / a.width, height: f.height / a.height)
        label = r.action.popupLabel(step: r.step)
        axis = Preferences.shared.cycleSizes ? r.action.cycleAxis : .none
        step = r.step % SnapAction.cycle.count
    }
}

private let ink = Color(red: 29 / 255, green: 35 / 255, blue: 43 / 255)
/// The ink at 88% over the light glass, as one opaque colour.
private let inkFill = Color(red: 56 / 255, green: 61 / 255, blue: 68 / 255)
private let ease = Animation.timingCurve(0.32, 0.72, 0, 1, duration: 0.24)

struct PopupView: View {
    @ObservedObject var model: PopupModel

    var body: some View {
        VStack(spacing: 14) {
            MiniDisplay(region: model.region, axis: model.axis)
            VStack(spacing: 9) {
                Text(model.label)
                    .font(.system(size: 14, weight: .semibold))
                    .tracking(-0.15)
                    .foregroundStyle(ink)
                    .lineLimit(1)
                if model.axis != .none {
                    HStack(spacing: 4) {
                        ForEach(0..<SnapAction.cycle.count, id: \.self) { i in
                            Capsule()
                                .fill(ink.opacity(i == model.step ? 0.88 : 0.22))
                                .frame(width: i == model.step ? 16 : 5, height: 5)
                        }
                    }
                }
            }
        }
        .padding(EdgeInsets(top: 20, leading: 20, bottom: 18, trailing: 20))
        .frame(width: 176)
        // Lightens the system glass toward the design. Circular corners to
        // match the panel's mask, which only clips the material, not this.
        .background(RoundedRectangle(cornerRadius: 28, style: .circular).fill(Color.white.opacity(0.28)))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .circular)
                .strokeBorder(Color.white.opacity(0.65), lineWidth: 0.5)
        )
        .animation(ease, value: model.region)
        .animation(ease, value: model.step)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(model.label)
    }
}

/// A 96×62 screen with ⅓ ½ ⅔ guides and the window's region filled in ink.
struct MiniDisplay: View {
    let region: CGRect
    let axis: SnapAction.CycleAxis

    private let size = CGSize(width: 96, height: 62)
    private let inset: CGFloat = 4

    var body: some View {
        let inner = CGSize(width: size.width - inset * 2, height: size.height - inset * 2)
        let fill = CGRect(x: inset + region.minX * inner.width, y: inset + region.minY * inner.height,
                          width: max(region.width * inner.width, 2), height: max(region.height * inner.height, 2))

        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(ink.opacity(0.3), lineWidth: 1.25)

            ForEach([1.0 / 3.0, 0.5, 2.0 / 3.0], id: \.self) { f in
                switch axis {
                case .width:
                    Rectangle().fill(ink.opacity(0.12))
                        .frame(width: 1, height: size.height - 12)
                        .offset(x: inset + inner.width * f, y: 6)
                case .height:
                    Rectangle().fill(ink.opacity(0.12))
                        .frame(width: size.width - 12, height: 1)
                        .offset(x: 6, y: inset + inner.height * f)
                case .none:
                    EmptyView()
                }
            }

            // Solid, so the guides don't show through the fill.
            RoundedRectangle(cornerRadius: min(7, fill.width / 2, fill.height / 2), style: .continuous)
                .fill(inkFill)
                .frame(width: fill.width, height: fill.height)
                .offset(x: fill.minX, y: fill.minY)
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
    }
}
