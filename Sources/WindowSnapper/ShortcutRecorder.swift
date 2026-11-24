import AppKit
import Carbon

/// Listens for the next key press in Settings and saves it as an action's
/// shortcut. Esc cancels; Delete on its own clears the shortcut.
final class ShortcutRecorder: ObservableObject {
    @Published private(set) var recording: SnapAction?
    /// Set when the last press was refused, so the field can say why.
    @Published private(set) var hint: String?

    private var monitor: Any?
    private let onRecordingChange: (Bool) -> Void

    init(onRecordingChange: @escaping (Bool) -> Void) {
        self.onRecordingChange = onRecordingChange
    }

    func start(_ action: SnapAction) {
        stop()
        recording = action
        hint = nil
        onRecordingChange(true)
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event)
            return nil
        }
    }

    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        hint = nil
        if recording != nil {
            recording = nil
            onRecordingChange(false)
        }
    }

    /// Shows the recording state without listening, for rendered snapshots.
    func preview(_ action: SnapAction?) { recording = action }

    private func handle(_ event: NSEvent) {
        guard let action = recording else { return }
        let mods = event.modifierFlags.intersection(Shortcut.relevant)

        if Int(event.keyCode) == kVK_Escape && mods.isEmpty {
            stop()
            return
        }
        if [kVK_Delete, kVK_ForwardDelete].contains(Int(event.keyCode)) && mods.isEmpty {
            Preferences.shared.setShortcut(nil, for: action)
            stop()
            return
        }
        // Shift alone would steal ordinary typing, so a shortcut needs ⌘, ⌥ or ⌃.
        guard !mods.intersection([.command, .option, .control]).isEmpty else {
            hint = "Add ⌘, ⌥ or ⌃"
            NSSound.beep()
            return
        }
        guard let shortcut = Shortcut(event: event) else {
            NSSound.beep()
            return
        }
        Preferences.shared.setShortcut(shortcut, for: action)
        stop()
    }
}
