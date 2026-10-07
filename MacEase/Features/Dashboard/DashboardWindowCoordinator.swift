import AppKit
import SwiftUI

@MainActor
final class DashboardWindowCoordinator: NSObject, NSWindowDelegate {
    private let model: AppModel
    private var window: NSWindow?

    init(model: AppModel) {
        self.model = model
    }

    func show() {
        if let window {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            return
        }

        let controller = NSHostingController(rootView: DashboardView(model: model))
        let window = NSWindow(contentViewController: controller)
        window.title = AppBrand.name
        window.setContentSize(NSSize(width: 880, height: 610))
        window.minSize = NSSize(width: 760, height: 540)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.hidesOnDeactivate = false
        window.backgroundColor = .clear
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
