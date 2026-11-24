import AppKit
import ApplicationServices
import ServiceManagement
import SwiftUI

// MARK: - Window

final class SettingsWindowController: NSObject, NSWindowDelegate {
    private let recorder: ShortcutRecorder
    private var window: NSWindow?

    init(recorder: ShortcutRecorder) {
        self.recorder = recorder
    }

    func show() {
        let window = self.window ?? makeWindow()
        self.window = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: SettingsView.size),
                              styleMask: [.titled, .closable, .fullSizeContentView],
                              backing: .buffered, defer: false)
        window.title = "Window Snapper Settings"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.appearance = NSAppearance(named: .aqua) // the design is light
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.contentView = NSHostingView(rootView: SettingsView(prefs: .shared, recorder: recorder))
        window.center()
        return window
    }

    func windowWillClose(_ notification: Notification) {
        recorder.stop()
    }

    func windowDidResignKey(_ notification: Notification) {
        recorder.stop()
    }
}

// MARK: - Palette

private enum Palette {
    static let ink = Color(red: 29 / 255, green: 35 / 255, blue: 43 / 255)
    static let secondary = Color(red: 57 / 255, green: 65 / 255, blue: 75 / 255)
    static let muted = Color(red: 72 / 255, green: 81 / 255, blue: 92 / 255)
}

/// Rendered snapshots can't draw system materials, so they swap in a flat tint.
private struct SnapshotKey: EnvironmentKey { static let defaultValue = false }
extension EnvironmentValues {
    var isSnapshot: Bool {
        get { self[SnapshotKey.self] }
        set { self[SnapshotKey.self] = newValue }
    }
}

// MARK: - Glass

/// Clear white glass over the painting: blur, a light tint, a hairline
/// highlight and two soft shadows so the card floats.
private struct Glass: ViewModifier {
    var radius: CGFloat = 14
    var floating = true
    @Environment(\.isSnapshot) private var isSnapshot

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content
            .background {
                ZStack {
                    if isSnapshot {
                        shape.fill(Color.white.opacity(0.62))
                    } else {
                        shape.fill(.ultraThinMaterial)
                        shape.fill(Color.white.opacity(0.32))
                    }
                }
            }
            .overlay(shape.strokeBorder(Color.white.opacity(0.65), lineWidth: 0.5))
            .shadow(color: Palette.ink.opacity(floating ? 0.07 : 0), radius: 12, y: 8)
            .shadow(color: Palette.ink.opacity(floating ? 0.08 : 0), radius: 28, y: 24)
    }
}

private extension View {
    func glass(radius: CGFloat = 14, floating: Bool = true) -> some View {
        modifier(Glass(radius: radius, floating: floating))
    }
}

// MARK: - Settings

struct SettingsView: View {
    static let size = CGSize(width: 600, height: 740)

    enum Tab: String, CaseIterable, Identifiable {
        case shortcuts = "Shortcuts", general = "General"
        var id: String { rawValue }
    }

    @ObservedObject var prefs: Preferences
    @ObservedObject var recorder: ShortcutRecorder
    @State var tab: Tab = .shortcuts

    /// The settings list differs from the menu: maximise to restore share a card.
    private static let sections: [[SnapAction]] = [
        [.leftHalf, .rightHalf, .topHalf, .bottomHalf],
        [.topLeft, .topRight, .bottomLeft, .bottomRight],
        [.maximise, .centre, .nextDisplay, .previousDisplay, .restore],
    ]

    var body: some View {
        ZStack {
            PaintedBackground()
            VStack(alignment: .leading, spacing: 12) {
                header
                switch tab {
                case .shortcuts: shortcutsPane
                case .general: GeneralPane(prefs: prefs)
                }
                Spacer(minLength: 0)
                footer
            }
            .padding(EdgeInsets(top: 40, leading: 20, bottom: 20, trailing: 20))
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .foregroundStyle(Palette.ink)
        .environment(\.colorScheme, .light)
        .onChange(of: tab) { _ in recorder.stop() }
    }

    private var header: some View {
        HStack {
            Text(tab.rawValue)
                .font(.system(size: 22, weight: .semibold))
                .tracking(-0.4)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            HStack(spacing: 2) {
                ForEach(Tab.allCases) { t in
                    Button(t.rawValue) { tab = t }
                        .buttonStyle(TabButtonStyle(selected: t == tab))
                        .accessibilityAddTraits(t == tab ? .isSelected : [])
                }
            }
            .padding(3)
            .glass(radius: 10, floating: false)
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 4)
    }

    private var shortcutsPane: some View {
        VStack(spacing: 12) {
            ForEach(Self.sections.indices, id: \.self) { i in
                VStack(spacing: 0) {
                    ForEach(Self.sections[i], id: \.self) { action in
                        ShortcutRow(action: action, shortcut: prefs.shortcuts[action], recorder: recorder) {
                            prefs.setShortcut(nil, for: action)
                        }
                    }
                }
                .padding(.vertical, 4)
                .glass()
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cycle sizes on repeat").font(.system(size: 13, weight: .medium))
                    Text("Press a half again for ⅔, then ⅓").font(.system(size: 12)).foregroundStyle(Palette.muted)
                }
                Spacer()
                Toggle("Cycle sizes on repeat", isOn: $prefs.cycleSizes)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .tint(Palette.ink)
            }
            .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 14))
            .glass()
        }
    }

    private var footer: some View {
        HStack(alignment: .bottom) {
            WallLabel(title: "Sunny Day", artist: "Clarice Beckett")
            Spacer()
            if tab == .shortcuts {
                Button("Restore Spectacle defaults") { prefs.restoreSpectacleDefaults() }
                    .buttonStyle(GlassPillStyle())
                    .disabled(prefs.isUsingDefaults)
            }
        }
    }
}

// MARK: - Rows

private struct ShortcutRow: View {
    let action: SnapAction
    let shortcut: Shortcut?
    @ObservedObject var recorder: ShortcutRecorder
    let clear: () -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 10) {
            Image(nsImage: action.glyph)
                .renderingMode(.template)
                .accessibilityHidden(true)
            Text(action.title).font(.system(size: 13))
            Spacer()
            if recorder.recording == action {
                Button { recorder.stop() } label: {
                    Text(recorder.hint ?? "Type a shortcut…")
                        .font(.system(size: 12))
                        .foregroundStyle(Palette.muted)
                        .padding(.horizontal, 10)
                        .frame(height: 24)
                        .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(Color.white.opacity(0.9)))
                        .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).strokeBorder(Palette.ink.opacity(0.85), lineWidth: 1.5))
                }
                .buttonStyle(.plain)
                .help("Esc cancels. Delete clears the shortcut.")
                .accessibilityLabel("\(action.title): recording a new shortcut")
            } else {
                Button { recorder.start(action) } label: {
                    if let shortcut {
                        HStack(spacing: 3) {
                            ForEach(Array(shortcut.caps.enumerated()), id: \.offset) { _, cap in Keycap(text: cap) }
                        }
                    } else {
                        Text("Record shortcut")
                            .font(.system(size: 12))
                            .foregroundStyle(Palette.muted)
                            .padding(.horizontal, 10)
                            .frame(height: 22)
                            .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(Palette.ink.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [3, 2])))
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(action.title) shortcut, \(shortcut?.displayString ?? "none"). Click to change")
            }

            // Remove: shown on hover, in a fixed slot so the keycaps don't shift.
            Button(action: clear) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.ink.opacity(0.35))
            }
            .buttonStyle(.plain)
            .frame(width: 16)
            .opacity(hovering && shortcut != nil && recorder.recording != action ? 1 : 0)
            .disabled(shortcut == nil)
            .help("Remove shortcut")
            .accessibilityLabel("Remove \(action.title) shortcut")
            .accessibilityHidden(shortcut == nil)
        }
        .frame(height: 34)
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .contextMenu {
            Button("Record New Shortcut") { recorder.start(action) }
            Button("Remove Shortcut", action: clear).disabled(shortcut == nil)
        }
    }
}

private struct Keycap: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11.5, weight: .medium))
            .padding(.horizontal, 5)
            .frame(minWidth: 22, minHeight: 22)
            .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color.white.opacity(0.72)))
            .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).strokeBorder(Palette.ink.opacity(0.12), lineWidth: 0.5))
            .shadow(color: Palette.ink.opacity(0.12), radius: 0, y: 1)
    }
}

// MARK: - General

private struct GeneralPane: View {
    @ObservedObject var prefs: Preferences
    @State private var openAtLogin = SMAppService.mainApp.status == .enabled
    @State private var trusted = AXIsProcessTrusted()

    var body: some View {
        VStack(spacing: 0) {
            row("Open at login", detail: nil) {
                Toggle("Open at login", isOn: $openAtLogin)
                    .labelsHidden().toggleStyle(.switch).controlSize(.small).tint(Palette.ink)
                    .onChange(of: openAtLogin) { on in
                        do {
                            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
                        } catch {
                            NSSound.beep()
                            openAtLogin = SMAppService.mainApp.status == .enabled
                        }
                    }
            }
            divider
            row("Show snap pop-up", detail: "The glass tile that shows where the window went") {
                Toggle("Show snap pop-up", isOn: $prefs.showPopup)
                    .labelsHidden().toggleStyle(.switch).controlSize(.small).tint(Palette.ink)
            }
            divider
            row("Accessibility", detail: trusted ? "Allowed. Window Snapper can move windows." : "Needed to move other apps’ windows") {
                if !trusted {
                    Button("Open Settings") {
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                    }
                    .buttonStyle(GlassPillStyle())
                }
            }
        }
        .padding(.vertical, 4)
        .glass()
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in trusted = AXIsProcessTrusted() }
    }

    private var divider: some View {
        Rectangle().fill(Palette.ink.opacity(0.08)).frame(height: 1).padding(.leading, 16)
    }

    private func row<Accessory: View>(_ title: String, detail: String?, @ViewBuilder accessory: () -> Accessory) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13, weight: .medium))
                if let detail { Text(detail).font(.system(size: 12)).foregroundStyle(Palette.muted) }
            }
            Spacer()
            accessory()
        }
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 14))
    }
}

// MARK: - Pieces

private struct TabButtonStyle: ButtonStyle {
    let selected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(selected ? Palette.ink : Palette.secondary)
            .padding(.horizontal, 14)
            .frame(height: 26)
            .background {
                if selected {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.white.opacity(0.92))
                        .shadow(color: Palette.ink.opacity(0.12), radius: 1.5, y: 1)
                }
            }
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

private struct GlassPillStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 14)
            .frame(height: 30)
            .glass(radius: 15, floating: false)
            .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.45)
    }
}

private struct WallLabel: View {
    let title: String
    let artist: String

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title).font(.system(size: 14, design: .serif).italic())
            Text(artist).font(.system(size: 11)).foregroundStyle(Palette.muted)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glass(radius: 10, floating: false)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Painting: \(title), by \(artist)")
    }
}

/// The painting, a white wash for contrast, and three soft colour blobs that
/// drift over it. Each blob wanders on its own slow loop (different periods
/// across x and y, so the pattern never visibly repeats). Still under Reduce Motion.
private struct PaintedBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let painting: NSImage? = Bundle.main.url(forResource: "sunny-day", withExtension: "jpg")
        .flatMap(NSImage.init(contentsOf:))

    private struct Blob {
        let color: Color
        let size: CGSize
        let centre: CGPoint     // offset from the window's centre
        let reach: CGSize       // how far it wanders
        let periods: (x: Double, y: Double)
        let phase: Double
    }

    private static let blobs: [Blob] = [
        Blob(color: Color(red: 120 / 255, green: 165 / 255, blue: 215 / 255).opacity(0.55),
             size: CGSize(width: 420, height: 480), centre: CGPoint(x: -130, y: -170),
             reach: CGSize(width: 150, height: 130), periods: (23, 31), phase: 0),
        Blob(color: Color(red: 232 / 255, green: 160 / 255, blue: 150 / 255).opacity(0.5),
             size: CGSize(width: 380, height: 440), centre: CGPoint(x: 150, y: 40),
             reach: CGSize(width: 140, height: 170), periods: (29, 19), phase: 2.1),
        Blob(color: Color(red: 226 / 255, green: 204 / 255, blue: 140 / 255).opacity(0.5),
             size: CGSize(width: 420, height: 400), centre: CGPoint(x: -20, y: 230),
             reach: CGSize(width: 170, height: 110), periods: (17, 27), phase: 4.2),
    ]

    var body: some View {
        ZStack {
            Color(red: 0.9, green: 0.86, blue: 0.8)
            if let painting = Self.painting {
                Image(nsImage: painting)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
                    .frame(width: SettingsView.size.width, height: SettingsView.size.height)
                    .clipped()
                    .contrast(0.9)
                    .brightness(0.03)
            }
            Color.white.opacity(0.2)
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
                let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
                ZStack {
                    ForEach(Self.blobs.indices, id: \.self) { i in
                        blob(Self.blobs[i], at: t)
                    }
                }
                // Full-window canvas: drawingGroup clips to its frame, and the
                // blobs wander well past their own size.
                .frame(width: SettingsView.size.width, height: SettingsView.size.height)
                .drawingGroup()
            }
        }
        .frame(width: SettingsView.size.width, height: SettingsView.size.height)
        .clipped()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func blob(_ b: Blob, at t: Double) -> some View {
        let x = b.centre.x + b.reach.width * sin(2 * .pi * t / b.periods.x + b.phase)
        let y = b.centre.y + b.reach.height * sin(2 * .pi * t / b.periods.y + b.phase * 1.3)
        let scale = 1 + 0.12 * sin(2 * .pi * t / (b.periods.x + b.periods.y) + b.phase)
        return Ellipse()
            .fill(RadialGradient(colors: [b.color, b.color.opacity(0)], center: .center,
                                 startRadius: 0, endRadius: min(b.size.width, b.size.height) / 2))
            .frame(width: b.size.width, height: b.size.height)
            .scaleEffect(scale)
            .blur(radius: 30)
            .offset(x: x, y: y)
    }
}

// MARK: - Snapshots

/// `--render-settings <folder>` writes PNGs of Settings (both tabs, and a
/// shortcut being recorded), drawn in an offscreen window.
enum SettingsSnapshots {
    private static var keepAlive: [NSWindow] = []

    static func write(to folder: URL, recorder: ShortcutRecorder, done: @escaping () -> Void) {
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let shots: [(String, SettingsView.Tab, SnapAction?)] = [
            ("settings-shortcuts", .shortcuts, nil),
            ("settings-recording", .shortcuts, .topHalf),
            ("settings-general", .general, nil),
        ]
        var remaining = shots.count
        for (i, shot) in shots.enumerated() {
            let shotRecorder = ShortcutRecorder { _ in }
            shotRecorder.preview(shot.2)
            let view = SettingsView(prefs: .shared, recorder: shotRecorder, tab: shot.1).environment(\.isSnapshot, true)
            let hosting = NSHostingView(rootView: view)
            let window = NSWindow(contentRect: NSRect(x: -20000 - i * 700, y: 0, width: 600, height: 740),
                                  styleMask: [.borderless], backing: .buffered, defer: false)
            window.appearance = NSAppearance(named: .aqua)
            window.contentView = hosting
            window.orderFrontRegardless()
            keepAlive.append(window)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                hosting.layoutSubtreeIfNeeded()
                if let rep = hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds) {
                    hosting.cacheDisplay(in: hosting.bounds, to: rep)
                    try? rep.representation(using: .png, properties: [:])?.write(to: folder.appendingPathComponent("\(shot.0).png"))
                }
                remaining -= 1
                if remaining == 0 { done() }
            }
        }
    }
}
