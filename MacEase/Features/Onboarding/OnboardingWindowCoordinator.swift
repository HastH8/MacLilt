import AppKit
import SwiftUI

@MainActor
final class OnboardingWindowCoordinator: NSObject, NSWindowDelegate {
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

        let rootView = OnboardingView(model: model) { [weak self] in
            self?.window?.close()
        }
        let controller = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: controller)
        window.title = "Welcome to \(AppBrand.name)"
        window.setContentSize(NSSize(width: 820, height: 560))
        window.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.hidesOnDeactivate = false
        window.level = .floating
        window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        window.backgroundColor = .clear
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
