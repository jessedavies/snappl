import AppKit
import ApplicationServices
import Combine
import ServiceManagement
import SwiftUI

/// First run. Two steps on *Yarra Winter Night*:
/// 1. **Ask:** what the Accessibility permission does (and doesn't), and a
///    button that registers Snappl with macOS and opens the right pane. It
///    watches for the grant and moves on by itself.
/// 2. **Try it:** press the real ⌥⌘← and watch it cycle ½ → ⅔ → ⅓, with the
///    real pop-up. The last thing a new person does is the thing the app is for.
final class OnboardingModel: ObservableObject {
    enum Step { case ask, tryIt }

    @Published var step: Step
    @Published var trusted: Bool
    /// -1 before the first press, then 0, 1, 2 around the cycle.
    @Published var demoStep = -1
    @Published var presses = 0

    private var timer: AnyCancellable?

    init(trusted: Bool = AXIsProcessTrusted()) {
        self.trusted = trusted
        self.step = trusted ? .tryIt : .ask
    }

    func startWatching() {
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self, !self.trusted, AXIsProcessTrusted() else { return }
            self.trusted = true
            withAnimation(.timingCurve(0.32, 0.72, 0, 1, duration: 0.24)) { self.step = .tryIt }
        }
    }

    func stopWatching() { timer = nil }

    /// Registers Snappl in the Accessibility list (the system prompt) and opens
    /// the pane, so the person only has to flip one switch.
    func requestAccess() {
        let prompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        AXIsProcessTrustedWithOptions([prompt: true] as CFDictionary)
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }

    /// A press of the left-half shortcut (or a click on the keycaps).
    func press() {
        presses += 1
        demoStep = (demoStep + 1) % SnapAction.cycle.count
    }

    var demoLabel: String {
        demoStep < 0 ? "Full screen" : SnapAction.leftHalf.popupLabel(step: demoStep)
    }

    var demoRegion: CGRect {
        demoStep < 0 ? CGRect(x: 0, y: 0, width: 1, height: 1)
            : CGRect(x: 0, y: 0, width: SnapAction.cycle[demoStep], height: 1)
    }
}

final class OnboardingWindowController: NSObject, NSWindowDelegate {
    static let size = CGSize(width: 600, height: 580)
    private static let doneKey = "hasFinishedFirstRun"

    let model = OnboardingModel()
    private var window: NSWindow?
    private var appearanceWatch: AnyCancellable?
    private let onDemoPress: (Int) -> Void

    /// `onDemoPress` receives the cycle step so the app can show the real pop-up.
    init(onDemoPress: @escaping (Int) -> Void) {
        self.onDemoPress = onDemoPress
    }

    static var hasFinished: Bool { UserDefaults.standard.bool(forKey: doneKey) }

    /// True while first run is open in front, so the left-half shortcut drives the demo.
    var isTakingShortcuts: Bool { window?.isKeyWindow == true && model.step == .tryIt }

    func show() {
        model.trusted = AXIsProcessTrusted()
        if model.trusted { model.step = .tryIt }
        let window = self.window ?? makeWindow()
        self.window = window
        model.startWatching()
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func demoPress() {
        withAnimation(.timingCurve(0.32, 0.72, 0, 1, duration: 0.24)) { model.press() }
        onDemoPress(model.demoStep)
    }

    private func finish() {
        UserDefaults.standard.set(true, forKey: Self.doneKey)
        window?.close()
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: Self.size),
                              styleMask: [.titled, .closable, .fullSizeContentView],
                              backing: .buffered, defer: false)
        window.title = "Welcome to Snappl"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.appearance = Preferences.shared.appearance.nsAppearance
        appearanceWatch = Preferences.shared.$appearance.sink { [weak window] mode in window?.appearance = mode.nsAppearance }
        window.contentView = NSHostingView(rootView: OnboardingView(model: model, prefs: .shared,
                                                                    press: { [weak self] in self?.demoPress() },
                                                                    done: { [weak self] in self?.finish() }))
        window.center()
        return window
    }

    func windowWillClose(_ notification: Notification) {
        model.stopWatching()
    }
}

// MARK: - View

struct OnboardingView: View {
    @ObservedObject var model: OnboardingModel
    @ObservedObject var prefs: Preferences
    let press: () -> Void
    let done: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            PaintedBackground(painting: "winter-night", size: OnboardingWindowController.size)
            VStack(alignment: .leading, spacing: 0) {
                Group {
                    switch model.step {
                    case .ask: AskStep(model: model)
                    case .tryIt: TryStep(model: model, prefs: prefs, press: press, done: done)
                    }
                }
                .padding(28)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glass(radius: 22)
                .transition(.opacity)
                Spacer(minLength: 0)
            }
            .padding(EdgeInsets(top: 52, leading: 32, bottom: 0, trailing: 32))
            WallLabel(title: "Yarra Winter Night, 1929", artist: "Clarice Beckett")
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
        .frame(width: OnboardingWindowController.size.width, height: OnboardingWindowController.size.height)
        .foregroundStyle(Theme.ink)
    }
}

private struct AskStep: View {
    @ObservedObject var model: OnboardingModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Image(nsImage: SnapAction.leftHalf.glyph)
                .resizable().renderingMode(.template).interpolation(.high)
                .frame(width: 24, height: 18)
                .frame(width: 44, height: 44)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.keycapRaised))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 8) {
                Text("Let Snappl move your windows")
                    .font(.system(size: 24, weight: .semibold)).tracking(-0.4)
                    .accessibilityAddTraits(.isHeader)
                Text("macOS asks before any app can move another app’s windows. Snappl only moves and resizes them. It never reads what’s inside.")
                    .font(.system(size: 14)).lineSpacing(4).foregroundStyle(Theme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            VStack(alignment: .leading, spacing: 10) {
                StepLine(number: 1, text: "Open Accessibility Settings")
                StepLine(number: 2, text: "Switch on Snappl")
            }
            HStack {
                HStack(spacing: 8) {
                    Circle().fill(Theme.ink.opacity(0.6)).frame(width: 6, height: 6)
                    Text("Waiting for access").font(.system(size: 12)).foregroundStyle(Theme.muted)
                }
                .accessibilityElement(children: .combine)
                Spacer()
                Button("Open Accessibility Settings", action: model.requestAccess)
                    .buttonStyle(InkButtonStyle(large: true))
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 4)
        }
    }
}

private struct StepLine: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Text("\(number)")
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 20, height: 20)
                .overlay(Circle().strokeBorder(Theme.ink.opacity(0.3), lineWidth: 1))
            Text(text).font(.system(size: 13))
        }
        .accessibilityElement(children: .combine)
    }
}

private struct TryStep: View {
    @ObservedObject var model: OnboardingModel
    @ObservedObject var prefs: Preferences
    @State private var openAtLogin = SMAppService.mainApp.status == .enabled
    let press: () -> Void
    let done: () -> Void

    private var keys: [String] {
        prefs.shortcuts[.leftHalf]?.caps ?? ["⌥", "⌘", "←"]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Access granted", systemImage: "checkmark.circle")
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(Theme.secondary)
                Text("Now try it")
                    .font(.system(size: 24, weight: .semibold)).tracking(-0.4)
                    .accessibilityAddTraits(.isHeader)
                Text(model.presses >= 3 ? "That’s the whole trick. It works the same on any window."
                     : "Press \(keys.joined()). Once for half, again for two thirds, again for a third.")
                    .font(.system(size: 14)).lineSpacing(4).foregroundStyle(Theme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack {
                Button(action: press) {
                    HStack(spacing: 6) {
                        ForEach(Array(keys.enumerated()), id: \.offset) { _, key in
                            BigKeycap(text: key, pressed: model.demoStep >= 0)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Press \(keys.joined())")
                Spacer()
                HStack(spacing: 14) {
                    Text(model.demoLabel).font(.system(size: 13, weight: .semibold))
                        .frame(minWidth: 110, alignment: .trailing)
                    MiniDisplay(region: model.demoRegion, axis: model.demoStep < 0 ? .none : .width)
                }
                .accessibilityElement(children: .combine)
            }
            .padding(EdgeInsets(top: 18, leading: 20, bottom: 18, trailing: 20))
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.well))
            VStack(spacing: 0) {
                row("Show the snap pop-up") {
                    Toggle("Show the snap pop-up", isOn: $prefs.showPopup)
                        .labelsHidden().toggleStyle(.switch).controlSize(.small).tint(Theme.switchTint)
                }
                row("Open at login") {
                    Toggle("Open at login", isOn: $openAtLogin)
                        .labelsHidden().toggleStyle(.switch).controlSize(.small).tint(Theme.switchTint)
                        .onChange(of: openAtLogin) { on in
                            do { if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() } }
                            catch { NSSound.beep(); openAtLogin = SMAppService.mainApp.status == .enabled }
                        }
                }
            }
            HStack {
                Text("Snappl lives in the menu bar. Settings are there too.")
                    .font(.system(size: 12)).foregroundStyle(Theme.muted)
                Spacer()
                Button("Done", action: done)
                    .buttonStyle(InkButtonStyle(large: false))
                    .keyboardShortcut(.defaultAction)
            }
        }
    }

    private func row<Accessory: View>(_ title: String, @ViewBuilder accessory: () -> Accessory) -> some View {
        HStack {
            Text(title).font(.system(size: 13))
            Spacer()
            accessory()
        }
        .frame(height: 34)
    }
}

/// The 44 pt keycap from the first-run design: lights up in ink when pressed.
private struct BigKeycap: View {
    let text: String
    let pressed: Bool

    var body: some View {
        Text(text)
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(pressed ? Theme.onInk : Theme.ink)
            .frame(width: 44, height: 44)
            .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(pressed ? Theme.inkSolid : Theme.keycapRaised))
            .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).strokeBorder(Theme.ink.opacity(pressed ? 0 : 0.12), lineWidth: 0.5))
            .shadow(color: Theme.ink.opacity(0.12), radius: 0, y: pressed ? 0 : 2)
            .animation(.easeOut(duration: 0.16), value: pressed)
    }
}

/// The one action a screen exists for: solid ink, fully rounded.
struct InkButtonStyle: ButtonStyle {
    let large: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Theme.onInk)
            .padding(.horizontal, large ? 20 : 22)
            .frame(height: large ? 40 : 36)
            .background(Capsule().fill(Theme.inkSolid))
            .shadow(color: .black.opacity(0.15), radius: 10, y: 6)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .contentShape(Capsule())
    }
}

// MARK: - Snapshots

/// `--render-onboarding <folder>`: both steps in light and dark, offscreen.
enum OnboardingSnapshots {
    private static var keepAlive: [NSWindow] = []

    static func write(to folder: URL, done: @escaping () -> Void) {
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let shots: [(String, OnboardingModel.Step, Int, NSAppearance.Name)] = [
            ("first-run-ask", .ask, -1, .aqua), ("first-run-ask-dark", .ask, -1, .darkAqua),
            ("first-run-try", .tryIt, 1, .aqua), ("first-run-try-dark", .tryIt, 1, .darkAqua),
        ]
        var remaining = shots.count
        for (i, shot) in shots.enumerated() {
            let model = OnboardingModel(trusted: shot.1 == .tryIt)
            model.step = shot.1
            model.demoStep = shot.2
            model.presses = shot.2 + 1
            let view = OnboardingView(model: model, prefs: .shared, press: {}, done: {}).environment(\.isSnapshot, true)
            let hosting = NSHostingView(rootView: view)
            let window = NSWindow(contentRect: NSRect(x: CGFloat(-30000 - i * 700), y: 0, width: OnboardingWindowController.size.width, height: OnboardingWindowController.size.height),
                                  styleMask: [.borderless], backing: .buffered, defer: false)
            window.appearance = NSAppearance(named: shot.3)
            window.contentView = hosting
            window.orderFrontRegardless()
            keepAlive.append(window)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
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
