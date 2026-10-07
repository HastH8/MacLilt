import AppKit
import SwiftUI

@MainActor
final class ClipboardHistoryWindowCoordinator: NSObject, NSWindowDelegate {
    private let monitor: ClipboardMonitor
    private let toast: ToastWindowCoordinator
    private var window: NSWindow?

    init(monitor: ClipboardMonitor, toast: ToastWindowCoordinator) {
        self.monitor = monitor
        self.toast = toast
    }

    func show() {
        if let window {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            return
        }

        let view = ClipboardHistoryView(monitor: monitor) { [weak self] entry in
            guard let self else { return }
            Task {
                if await self.monitor.restore(entry) {
                    self.toast.show(message: "Copied to clipboard", symbol: "doc.on.clipboard.fill")
                    self.window?.orderOut(nil)
                } else {
                    self.toast.show(message: "Item is no longer available", symbol: "exclamationmark.triangle.fill", isError: true)
                }
            }
        }
        let window = NSPanel(contentViewController: NSHostingController(rootView: view))
        window.title = "Clipboard History"
        window.setContentSize(NSSize(width: 620, height: 520))
        window.styleMask = [.titled, .closable, .resizable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = .clear
        window.hidesOnDeactivate = false
        window.isReleasedWhenClosed = false
        window.isMovableByWindowBackground = true
        window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        window.center()
        window.delegate = self
        self.window = window

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        guard notification.object as? NSWindow === window else { return }
        window = nil
    }
}
