import AppKit
import SwiftUI

struct WindowChromeConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> ConfiguringView {
        ConfiguringView()
    }

    func updateNSView(_ view: ConfiguringView, context: Context) {
        view.configureWindow()
    }
}

final class ConfiguringView: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        configureWindow()
    }

    func configureWindow() {
        guard let window else { return }
        window.appearance = NSAppearance(named: .darkAqua)
        window.titlebarAppearsTransparent = true
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hidesOnDeactivate = false
        window.collectionBehavior.insert(.moveToActiveSpace)
    }
}
