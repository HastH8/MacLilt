import SwiftUI

@main
struct MacEaseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarPanel(model: appDelegate.appModel)
        } label: {
            BrandIcon(size: 18, showsGlow: false)
                .accessibilityLabel(AppBrand.name)
        }
        .menuBarExtraStyle(.window)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings…") {
                    appDelegate.appModel.showSettings()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
