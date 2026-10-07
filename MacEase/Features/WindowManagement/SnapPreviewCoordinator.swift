import AppKit
import SwiftUI

@MainActor
final class SnapPreviewCoordinator {
    private var panel: NSPanel?

    func show(frame: CGRect, layout: WindowLayout) {
        let panel = self.panel ?? makePanel()
        let view = ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(MacEaseTheme.Colors.violet.opacity(0.20))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(MacEaseTheme.Colors.cyan.opacity(0.72), lineWidth: 2)
                }
            Label(layout.title, systemImage: layout.symbol)
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.black.opacity(0.48), in: Capsule())
        }
        panel.contentView = NSHostingView(rootView: view)
        panel.setFrame(frame.insetBy(dx: 7, dy: 7), display: true)
        panel.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        self.panel = panel
        return panel
    }
}
