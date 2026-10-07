import SwiftUI

private enum SettingsSection: String, CaseIterable, Identifiable {
    case general = "General"
    case features = "Features"
    case shortcuts = "Shortcuts"
    case permissions = "Permissions"
    case about = "About"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .general: "gearshape"
        case .features: "switch.2"
        case .shortcuts: "keyboard"
        case .permissions: "hand.raised"
        case .about: "info.circle"
        }
    }
}

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @ObservedObject private var launchAtLogin: LaunchAtLoginService
    @State private var selection: SettingsSection = .general

    init(model: AppModel) {
        self.model = model
        launchAtLogin = model.launchAtLogin
    }

    var body: some View {
        VStack(spacing: 0) {
            settingsNavigation
            Rectangle().fill(.white.opacity(0.07)).frame(height: 1)

            ScrollView {
                Group {
                    switch selection {
                    case .general:
                        GeneralSettings(model: model, launchAtLogin: launchAtLogin)
                    case .features:
                        FeatureSettings(model: model)
                    case .shortcuts:
                        ShortcutSettings(preferences: model.preferences)
                    case .permissions:
                        PermissionSettings(permissions: model.permissions)
                    case .about:
                        AboutSettings()
                    }
                }
                .frame(maxWidth: 760, alignment: .topLeading)
                .padding(.horizontal, 30)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear { model.refreshSystemState() }
    }

    private var settingsNavigation: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Settings")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    Text("Make MacEase work the way you do.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Done") { model.showDashboard() }
                    .buttonStyle(.borderedProminent)
                    .tint(MacEaseTheme.Colors.violet)
            }

            HStack(spacing: 7) {
                ForEach(SettingsSection.allCases) { section in
                    SettingsTab(section: section, isSelected: selection == section) {
                        withAnimation(MacEaseTheme.Motion.quick) { selection = section }
                    }
                }
            }
        }
        .padding(.horizontal, 30)
        .padding(.top, 18)
        .padding(.bottom, 16)
    }
}

private struct SettingsTab: View {
    let section: SettingsSection
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(section.rawValue, systemImage: section.symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? .white : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(isSelected ? MacEaseTheme.Colors.violet.opacity(0.72) : .white.opacity(0.045), in: RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? MacEaseTheme.Colors.violet.opacity(0.9) : .white.opacity(0.07))
                }
        }
        .buttonStyle(.plain)
    }
}

private struct GeneralSettings: View {
    let model: AppModel
    @ObservedObject var launchAtLogin: LaunchAtLoginService

    var body: some View {
        SettingsPage(title: "General", subtitle: "Startup and app behavior") {
            SettingsCard {
                SettingToggleRow(
                    title: "Launch at login",
                    detail: "Have MacEase ready in your Dock and menu bar after signing in.",
                    symbol: "power"
                ) {
                    Toggle("", isOn: Binding(
                        get: { launchAtLogin.isEnabled },
                        set: { launchAtLogin.setEnabled($0) }
                    ))
                    .labelsHidden()
                }

                if launchAtLogin.requiresApproval {
                    InlineNotice(text: "Approval is required in System Settings → General → Login Items.", symbol: "exclamationmark.circle", color: .orange)
                }
                if let error = launchAtLogin.lastError {
                    InlineNotice(text: error, symbol: "xmark.circle", color: .red)
                }
            }

            SettingsCard {
                HStack(spacing: 14) {
                    SettingsIcon(symbol: "sparkles.rectangle.stack")
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Guided tour").font(.body.weight(.semibold))
                        Text("Review the feature tour without resetting your choices.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Open Tour") { model.showOnboarding() }
                }
            }
        }
    }
}

private struct FeatureSettings: View {
    let model: AppModel
    @ObservedObject private var preferences: PreferenceStore

    init(model: AppModel) {
        self.model = model
        preferences = model.preferences
    }

    var body: some View {
        SettingsPage(title: "Features", subtitle: "Only enabled tools run in the background") {
            SettingsCard {
                FeatureToggleSetting(title: "Screenshot → Paste", detail: "Capture an area, window, or full screen directly to the clipboard.", symbol: "camera.viewfinder", isOn: Binding(
                    get: { preferences.preferredScreenshot },
                    set: { model.setScreenshotEnabled($0) }
                ))

                if preferences.preferredScreenshot {
                    OptionArea {
                        Toggle("Also save captures to Pictures/\(AppBrand.name)", isOn: $preferences.saveScreenshots)
                    }
                }
            }

            SettingsCard {
                FeatureToggleSetting(title: "Clipboard History", detail: "Keep a private, searchable history of text, images, and files.", symbol: "doc.on.clipboard", isOn: Binding(
                    get: { preferences.preferredClipboard },
                    set: { model.setClipboardEnabled($0) }
                ))

                if preferences.preferredClipboard {
                    OptionArea {
                        Toggle("Keep history between launches", isOn: Binding(
                            get: { preferences.clipboardPersistentHistory },
                            set: { preferences.clipboardPersistentHistory = $0; model.syncClipboardConfiguration() }
                        ))
                        Divider().overlay(.white.opacity(0.06))
                        HStack(spacing: 18) {
                            CompactStepper(title: "Items", value: preferences.clipboardItemLimit) {
                                Stepper("", value: Binding(
                                    get: { preferences.clipboardItemLimit },
                                    set: { preferences.clipboardItemLimit = $0; model.syncClipboardConfiguration() }
                                ), in: 10...2_000, step: 10).labelsHidden()
                            }
                            CompactStepper(title: "Days", value: preferences.clipboardRetentionDays) {
                                Stepper("", value: Binding(
                                    get: { preferences.clipboardRetentionDays },
                                    set: { preferences.clipboardRetentionDays = $0; model.syncClipboardConfiguration() }
                                ), in: 1...365).labelsHidden()
                            }
                            CompactStepper(title: "Image MB", value: preferences.clipboardStorageLimitMB) {
                                Stepper("", value: Binding(
                                    get: { preferences.clipboardStorageLimitMB },
                                    set: { preferences.clipboardStorageLimitMB = $0; model.syncClipboardConfiguration() }
                                ), in: 10...2_048, step: 10).labelsHidden()
                            }
                        }
                        TextField("Excluded apps, separated by commas", text: Binding(
                            get: { preferences.clipboardExcludedApplications },
                            set: { preferences.clipboardExcludedApplications = $0; model.syncClipboardConfiguration() }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                }
            }

            SettingsCard {
                FeatureToggleSetting(title: "Individual Window Switcher", detail: "Use ⌥Tab to move between real windows with live previews.", symbol: "rectangle.3.group", isOn: Binding(
                    get: { preferences.preferredWindowSwitcher },
                    set: { model.setWindowSwitcherEnabled($0) }
                ))
            }

            SettingsCard {
                FeatureToggleSetting(title: "Window Management", detail: "Snap, resize, center, restore, and move windows between displays.", symbol: "rectangle.split.2x2", isOn: Binding(
                    get: { preferences.preferredWindowManagement },
                    set: { model.setWindowManagementEnabled($0) }
                ))
            }

            SettingsCard {
                FeatureToggleSetting(title: "Middle Click", detail: "Open clipboard history while preserving normal middle-click behavior.", symbol: "computermouse", isOn: Binding(
                    get: { preferences.middleClickEnabled },
                    set: { model.setMiddleClickEnabled($0) }
                ))
                if preferences.middleClickEnabled {
                    OptionArea {
                        TextField("Excluded apps, separated by commas", text: $preferences.middleClickExcludedApplications)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }

            HStack(spacing: 12) {
                StatusChip(symbol: "folder.badge.gearshape", title: "Finder Tools", detail: "Ready", color: .green)
                StatusChip(symbol: "pin.slash", title: "Always on Top", detail: "Unavailable for other apps", color: .secondary)
            }
        }
    }
}

private struct FeatureToggleSetting: View {
    let title: String
    let detail: String
    let symbol: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            SettingsIcon(symbol: symbol)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.body.weight(.semibold))
                Text(detail).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 18)
            Toggle("", isOn: $isOn).labelsHidden()
        }
    }
}

private struct ShortcutSettings: View {
    @ObservedObject var preferences: PreferenceStore

    private var all: [ShortcutSpec] {
        [preferences.screenshotShortcut, preferences.clipboardShortcut, preferences.windowSwitcherShortcut]
    }

    var body: some View {
        SettingsPage(title: "Shortcuts", subtitle: "Click a shortcut, then press a new key combination") {
            SettingsCard {
                ShortcutSettingRow(title: "Screenshot → Paste", symbol: "camera.viewfinder", shortcut: $preferences.screenshotShortcut, all: all)
                SettingsDivider()
                ShortcutSettingRow(title: "Clipboard History", symbol: "doc.on.clipboard", shortcut: $preferences.clipboardShortcut, all: all)
                SettingsDivider()
                ShortcutSettingRow(title: "Window Switcher", symbol: "rectangle.3.group", shortcut: $preferences.windowSwitcherShortcut, all: all)
            }

            HStack {
                Label("⌃⌥Arrow controls window layouts", systemImage: "arrow.up.left.and.arrow.down.right")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("Restore Defaults") { preferences.restoreShortcutDefaults() }
            }
        }
    }
}

private struct ShortcutSettingRow: View {
    let title: String
    let symbol: String
    @Binding var shortcut: ShortcutSpec
    let all: [ShortcutSpec]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                SettingsIcon(symbol: symbol, size: 34)
                Text(title).font(.body.weight(.medium))
                Spacer()
                ShortcutRecorder(shortcut: $shortcut).frame(width: 130)
            }
            if let warning = ShortcutValidator.warning(for: shortcut, among: all) {
                InlineNotice(text: warning, symbol: "exclamationmark.triangle.fill", color: .orange)
            }
        }
    }
}

private struct PermissionSettings: View {
    @ObservedObject var permissions: PermissionCenter

    var body: some View {
        SettingsPage(title: "Permissions", subtitle: "MacEase only asks when a feature needs access") {
            SettingsCard {
                PermissionLine(title: "Accessibility", detail: "Needed to switch, move, and resize windows.", symbol: "hand.raised", state: permissions.accessibility, action: permissions.requestAccessibility)
                SettingsDivider()
                PermissionLine(title: "Screen Recording", detail: "Needed for window previews and screenshots.", symbol: "rectangle.inset.filled.and.person.filled", state: permissions.screenRecording, action: permissions.requestScreenRecording)
            }
            HStack {
                Text("Permission changes made in System Settings may take a moment to appear.")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("Refresh") { permissions.refresh() }
            }
        }
    }
}

private struct PermissionLine: View {
    let title: String
    let detail: String
    let symbol: String
    let state: PermissionState
    let action: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            SettingsIcon(symbol: symbol)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.body.weight(.semibold))
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(state.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(state == .granted ? .green : .secondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background((state == .granted ? Color.green : Color.white).opacity(0.08), in: Capsule())
            if state != .granted { Button("Review…", action: action) }
        }
    }
}

private struct AboutSettings: View {
    var body: some View {
        SettingsPage(title: "About", subtitle: AppBrand.tagline) {
            HStack(spacing: 20) {
                BrandIcon(size: 86)
                VStack(alignment: .leading, spacing: 6) {
                    Text(AppBrand.name).font(.system(size: 28, weight: .bold, design: .rounded))
                    Text("Version 0.1.0")
                        .font(.caption.weight(.medium)).foregroundStyle(.secondary)
                    Text("A private, local-first productivity toolkit for macOS.")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)

            SettingsCard {
                LabeledContent("Build", value: "Feature complete")
                SettingsDivider()
                LabeledContent("Minimum macOS", value: "14 Sonoma")
                SettingsDivider()
                LabeledContent("Data", value: "Stored locally on this Mac")
            }
        }
    }
}

private struct SettingsPage<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 23, weight: .bold, design: .rounded))
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) { content() }
            .padding(17)
            .frame(maxWidth: .infinity, alignment: .leading)
            .macEaseGlass(cornerRadius: 17)
    }
}

private struct SettingsIcon: View {
    let symbol: String
    var size: CGFloat = 38

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.4, weight: .semibold))
            .foregroundStyle(MacEaseTheme.Colors.cyan)
            .frame(width: size, height: size)
            .background(MacEaseTheme.Colors.blue.opacity(0.14), in: RoundedRectangle(cornerRadius: size * 0.28))
    }
}

private struct SettingToggleRow<Control: View>: View {
    let title: String
    let detail: String
    let symbol: String
    @ViewBuilder let control: () -> Control

    var body: some View {
        HStack(spacing: 14) {
            SettingsIcon(symbol: symbol)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.body.weight(.semibold))
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            control()
        }
    }
}

private struct OptionArea<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 11) { content() }
            .font(.caption)
            .padding(13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 12))
            .overlay { RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.055)) }
    }
}

private struct CompactStepper<Control: View>: View {
    let title: String
    let value: Int
    @ViewBuilder let control: () -> Control

    var body: some View {
        HStack(spacing: 7) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title).foregroundStyle(.secondary)
                Text("\(value)").font(.body.weight(.semibold))
            }
            Spacer(minLength: 2)
            control()
        }
        .frame(maxWidth: .infinity)
    }
}

private struct StatusChip: View {
    let symbol: String
    let title: String
    let detail: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol).foregroundStyle(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.caption.weight(.semibold))
                Text(detail).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
        .overlay { RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.06)) }
    }
}

private struct InlineNotice: View {
    let text: String
    let symbol: String
    let color: Color

    var body: some View {
        Label(text, systemImage: symbol)
            .font(.caption)
            .foregroundStyle(color)
            .padding(.leading, 52)
    }
}

private struct SettingsDivider: View {
    var body: some View {
        Divider().overlay(.white.opacity(0.06))
    }
}
