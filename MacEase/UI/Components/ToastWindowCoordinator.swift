import AppKit
import SwiftUI

@MainActor
final class ToastWindowCoordinator {
    private var panel: NSPanel?
    private var dismissalTask: Task<Void, Never>?

    func show(message: String, symbol: String, isError: Bool = false) {
        dismissalTask?.cancel()

        let view = HStack(spacing: 10) {
            Image(systemName: symbol)
                .foregroundStyle(isError ? Color.red : MacEaseTheme.Colors.cyan)
            Text(message).font(.system(size: 13, weight: .semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .foregroundStyle(.white)
        .background(.black.opacity(0.72), in: Capsule())
        .overlay { Capsule().stroke(.white.opacity(0.14)) }

        let panel = self.panel ?? makePanel()
        panel.contentView = NSHostingView(rootView: view)
        panel.contentView?.layoutSubtreeIfNeeded()
        let fittingSize = panel.contentView?.fittingSize ?? NSSize(width: 220, height: 46)
        panel.setContentSize(fittingSize)

        let screen = NSScreen.main ?? NSScreen.screens.first
        if let visibleFrame = screen?.visibleFrame {
            panel.setFrameOrigin(NSPoint(
                x: visibleFrame.midX - fittingSize.width / 2,
                y: visibleFrame.minY + 54
            ))
        }

        panel.alphaValue = 0
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            panel.animator().alphaValue = 1
        }

        dismissalTask = Task { [weak self, weak panel] in
            try? await Task.sleep(for: .seconds(1.8))
            guard !Task.isCancelled, let panel else { return }
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.18
                panel.animator().alphaValue = 0
            }, completionHandler: {
                Task { @MainActor in
                    panel.orderOut(nil)
                    self?.dismissalTask = nil
                }
            })
        }
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        self.panel = panel
        return panel
    }
}
