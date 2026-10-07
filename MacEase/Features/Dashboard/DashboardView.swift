import SwiftUI

struct DashboardView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ZStack {
            AmbientBackground()

            VStack(spacing: 0) {
                topBar
                Rectangle()
                    .fill(.white.opacity(0.08))
                    .frame(height: 1)

                Group {
                    switch model.dashboardRoute {
                    case .home:
                        DashboardHome(model: model)
                            .transition(.opacity.combined(with: .move(edge: .leading)))
                    case .settings:
                        SettingsView(model: model)
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }
                }
                .animation(MacEaseTheme.Motion.quick, value: model.dashboardRoute)
            }
        }
        .preferredColorScheme(.dark)
        .background(WindowChromeConfigurator().frame(width: 0, height: 0))
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            Button { model.showDashboard() } label: {
                HStack(spacing: 10) {
                    BrandIcon(size: 34, showsGlow: false)
                    Text(AppBrand.name)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: 4) {
                NavigationPill(title: "Home", symbol: "sparkles", isSelected: model.dashboardRoute == .home) {
                    model.showDashboard()
                }
                NavigationPill(title: "Settings", symbol: "slider.horizontal.3", isSelected: model.dashboardRoute == .settings) {
                    model.showSettings()
                }
            }
            .padding(4)
            .background(.white.opacity(0.055), in: Capsule())
            .overlay { Capsule().stroke(.white.opacity(0.08)) }

            Spacer()

            HStack(spacing: 7) {
                Circle().fill(.green).frame(width: 7, height: 7)
                Text("Running")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24)
        .frame(height: 64)
    }
}

private struct NavigationPill: View {
    let title: String
    let symbol: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? .white : .secondary)
                .padding(.horizontal, 13)
                .padding(.vertical, 7)
                .background(isSelected ? MacEaseTheme.Colors.violet.opacity(0.72) : .clear, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct DashboardHome: View {
    @ObservedObject var model: AppModel

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                header

                LazyVGrid(columns: columns, spacing: 14) {
                    DashboardAction(title: "Screenshot → Paste", detail: "Capture an area, window, or full screen", symbol: "camera.viewfinder", shortcut: model.preferences.screenshotShortcut.displayValue) {
                        model.captureScreenshot()
                    }
                    DashboardAction(title: "Clipboard History", detail: "Search text, images, and copied files", symbol: "doc.on.clipboard", shortcut: model.preferences.clipboardShortcut.displayValue) {
                        model.showClipboardHistory()
                    }
                    DashboardAction(title: "Window Switcher", detail: "Switch between individual windows", symbol: "rectangle.3.group", shortcut: model.preferences.windowSwitcherShortcut.displayValue) {
                        model.showWindowSwitcher()
                    }
                    DashboardAction(title: "Tile Left", detail: "Move the focused window to the left half", symbol: "rectangle.lefthalf.inset.filled", shortcut: "⌃⌥←") {
                        model.applyWindowLayout(.leftHalf)
                    }
                    DashboardAction(title: "Tile Right", detail: "Move the focused window to the right half", symbol: "rectangle.righthalf.inset.filled", shortcut: "⌃⌥→") {
                        model.applyWindowLayout(.rightHalf)
                    }
                    DashboardAction(title: "Finder Tools", detail: "Copy paths from the current Finder selection", symbol: "folder.badge.gearshape", shortcut: nil) {
                        model.copyFinderPaths()
                    }
                }

                HStack {
                    Label("MacEase remains available in the Dock and menu bar.", systemImage: "dock.rectangle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Onboarding") { model.showOnboarding() }
                    Button("Open Settings") { model.showSettings() }
                        .buttonStyle(.borderedProminent)
                        .tint(MacEaseTheme.Colors.violet)
                }
                .padding(.top, 2)
            }
            .padding(30)
        }
    }

    private var header: some View {
        HStack(spacing: 18) {
            BrandIcon(size: 70)
            VStack(alignment: .leading, spacing: 5) {
                Text("Everything you need, one click away.")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text(AppBrand.tagline)
                    .font(.title3)
                    .foregroundStyle(MacEaseTheme.Colors.secondaryText)
            }
            Spacer()
        }
    }
}

private struct DashboardAction: View {
    let title: String
    let detail: String
    let symbol: String
    let shortcut: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(MacEaseTheme.Colors.cyan)
                    .frame(width: 46, height: 46)
                    .background(MacEaseTheme.Colors.blue.opacity(0.15), in: RoundedRectangle(cornerRadius: 13))
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline)
                    Text(detail).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                }
                Spacer(minLength: 8)
                if let shortcut {
                    Text(shortcut)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
            .contentShape(RoundedRectangle(cornerRadius: 17))
        }
        .buttonStyle(.plain)
        .macEaseGlass(cornerRadius: 17)
    }
}
