import AppKit
import SwiftUI

struct MenuBarPanel: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 11) {
                BrandIcon(size: 36)
                VStack(alignment: .leading, spacing: 1) {
                    Text(AppBrand.name).font(.headline)
                    Text("Productivity tools are active").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Circle().fill(.green).frame(width: 7, height: 7)
                    .accessibilityLabel("MacEase is running")
            }
            .padding(16)

            Divider()

            VStack(spacing: 12) {
                Menu {
                    ForEach(ScreenshotMode.allCases, id: \.rawValue) { mode in
                        Button(mode.title) { model.captureScreenshot(mode) }
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "camera.viewfinder")
                            .foregroundStyle(MacEaseTheme.Colors.cyan)
                            .frame(width: 28, height: 28)
                            .background(MacEaseTheme.Colors.blue.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Screenshot → Paste").font(.system(size: 13, weight: .semibold))
                            Text("Area, window, or full screen").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
                .menuStyle(.borderlessButton)
                QuickActionRow(symbol: "doc.on.clipboard", title: "Clipboard History", detail: "Search copied text, images, and files") {
                    model.showClipboardHistory()
                }
                QuickActionRow(symbol: "rectangle.3.group", title: "Window Switcher", detail: "Switch between individual windows") {
                    model.showWindowSwitcher()
                }
                Menu {
                    Section("Halves") {
                        Button("Left Half") { model.applyWindowLayout(.leftHalf) }
                        Button("Right Half") { model.applyWindowLayout(.rightHalf) }
                    }
                    Section("Quarters") {
                        Button("Top Left") { model.applyWindowLayout(.topLeftQuarter) }
                        Button("Top Right") { model.applyWindowLayout(.topRightQuarter) }
                        Button("Bottom Left") { model.applyWindowLayout(.bottomLeftQuarter) }
                        Button("Bottom Right") { model.applyWindowLayout(.bottomRightQuarter) }
                    }
                    Section("Thirds") {
                        Button("Left Third") { model.applyWindowLayout(.leftThird) }
                        Button("Center Third") { model.applyWindowLayout(.centerThird) }
                        Button("Right Third") { model.applyWindowLayout(.rightThird) }
                    }
                    Section("More") {
                        Button("Maximize") { model.applyWindowLayout(.maximize) }
                        Button("Center") { model.applyWindowLayout(.center) }
                        Button("Move to Next Display") { model.applyWindowLayout(.nextDisplay) }
                        Button("Restore Previous Bounds") { model.applyWindowLayout(.restore) }
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "rectangle.split.2x2")
                            .foregroundStyle(MacEaseTheme.Colors.cyan)
                            .frame(width: 28, height: 28)
                            .background(MacEaseTheme.Colors.blue.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Window Layout").font(.system(size: 13, weight: .semibold))
                            Text("Halves, quarters, thirds, and displays").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .menuStyle(.borderlessButton)

                Menu {
                    Button("Copy Selected Paths") { model.copyFinderPaths() }
                    Button("Copy Selected File References") { model.copyFinderFileReferences() }
                    Button("Create New File…") { model.createNewFinderFile() }
                    Divider()
                    Button("Reveal Clipboard Files") { model.revealClipboardFiles() }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "folder.badge.gearshape")
                            .foregroundStyle(MacEaseTheme.Colors.cyan)
                            .frame(width: 28, height: 28)
                            .background(MacEaseTheme.Colors.blue.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Finder Tools").font(.system(size: 13, weight: .semibold))
                            Text("Paths, file references, and new files").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .menuStyle(.borderlessButton)
            }
            .padding(16)

            Divider()

            HStack(spacing: 8) {
                Button("Open MacEase") { model.showDashboard() }
                Button("Onboarding") { model.showOnboarding() }
                Button("Settings") { model.showSettings() }
                Spacer()
                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Image(systemName: "power")
                }
                .help("Quit \(AppBrand.name)")
                .accessibilityLabel("Quit \(AppBrand.name)")
            }
            .buttonStyle(.borderless)
            .padding(14)
        }
        .frame(width: 340)
        .background(AmbientBackground())
        .preferredColorScheme(.dark)
    }
}

private struct QuickActionRow: View {
    let symbol: String
    let title: String
    let detail: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MacEaseTheme.Colors.cyan)
                    .frame(width: 28, height: 28)
                    .background(MacEaseTheme.Colors.blue.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 13, weight: .semibold))
                    Text(detail).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
