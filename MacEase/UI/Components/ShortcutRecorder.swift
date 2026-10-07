import AppKit
import SwiftUI

struct ShortcutRecorder: NSViewRepresentable {
    @Binding var shortcut: ShortcutSpec

    func makeCoordinator() -> Coordinator {
        Coordinator(shortcut: $shortcut)
    }

    func makeNSView(context: Context) -> ShortcutCaptureButton {
        let button = ShortcutCaptureButton()
        button.bezelStyle = .rounded
        button.controlSize = .regular
        button.target = context.coordinator
        button.action = #selector(Coordinator.beginRecording(_:))
        button.onShortcut = { context.coordinator.commit($0, button: button) }
        button.title = shortcut.displayValue
        return button
    }

    func updateNSView(_ button: ShortcutCaptureButton, context: Context) {
        context.coordinator.shortcut = $shortcut
        if !button.isRecording { button.title = shortcut.displayValue }
    }

    @MainActor
    final class Coordinator: NSObject {
        var shortcut: Binding<ShortcutSpec>

        init(shortcut: Binding<ShortcutSpec>) {
            self.shortcut = shortcut
        }

        @objc func beginRecording(_ sender: ShortcutCaptureButton) {
            sender.isRecording = true
            sender.title = "Type shortcut…"
            sender.window?.makeFirstResponder(sender)
        }

        func commit(_ value: ShortcutSpec?, button: ShortcutCaptureButton) {
            button.isRecording = false
            if let value { shortcut.wrappedValue = value }
            button.title = shortcut.wrappedValue.displayValue
            button.window?.makeFirstResponder(nil)
        }
    }
}

final class ShortcutCaptureButton: NSButton {
    var isRecording = false
    var onShortcut: ((ShortcutSpec?) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }
        if event.keyCode == 53 {
            onShortcut?(nil)
            return
        }
        guard let key = event.charactersIgnoringModifiers, !key.isEmpty else { return }
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard !modifiers.isEmpty else {
            NSSound.beep()
            return
        }
        onShortcut?(ShortcutSpec(key: key, modifiers: modifiers))
    }
}
