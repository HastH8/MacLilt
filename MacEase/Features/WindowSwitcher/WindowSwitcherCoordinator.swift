import AppKit
import SwiftUI

private final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

@MainActor
final class WindowSwitcherCoordinator {
    let model: WindowSwitcherModel
    private var panel: NSPanel?

    init(model: WindowSwitcherModel = WindowSwitcherModel()) {
        self.model = model
    }

    var isVisible: Bool { panel?.isVisible == true }

    func showAndCycle(reverse: Bool = false) {
        if panel == nil { makePanel() }
        if !isVisible {
            model.reload(reverse: reverse)
            positionPanel()
            panel?.orderFrontRegardless()
        } else {
            model.move(by: reverse ? -1 : 1)
        }
    }

    func move(by offset: Int) {
        guard isVisible else { return }
        model.move(by: offset)
    }

    func commit() {
        guard isVisible else { return }
        model.activateSelection()
        panel?.orderOut(nil)
    }

    func cancel() {
        guard isVisible else { return }
        model.close()
        panel?.orderOut(nil)
    }

    private func makePanel() {
        let view = WindowSwitcherView(model: model) { [weak self] window in
            self?.model.activate(window)
            self?.panel?.orderOut(nil)
        }
        let panel = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 178),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentView = NSHostingView(rootView: view)
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        self.panel = panel
    }

    private func positionPanel() {
        guard let panel, let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let width = min(max(CGFloat(model.windows.count) * 208 + 24, 230), min(screen.visibleFrame.width - 60, 1_100))
        let height: CGFloat = 178
        panel.setFrame(NSRect(
            x: screen.visibleFrame.midX - width / 2,
            y: screen.visibleFrame.midY - height / 2,
            width: width,
            height: height
        ), display: true)
    }
}
