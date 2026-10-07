import SwiftUI

struct OnboardingView: View {
    @ObservedObject var model: AppModel
    @ObservedObject private var preferences: PreferenceStore
    @ObservedObject private var permissions: PermissionCenter
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page: OnboardingPage = .welcome
    let close: () -> Void

    init(model: AppModel, close: @escaping () -> Void) {
        self.model = model
        preferences = model.preferences
        permissions = model.permissions
        self.close = close
    }

    var body: some View {
        ZStack {
            AmbientBackground()
            VStack(spacing: 0) {
                pageIndicator.padding(.top, 18)
                pageContent
                    .id(page)
                    .transition(reduceMotion ? .opacity : .asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.985)), removal: .opacity))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                footer.padding(.horizontal, 28).padding(.bottom, 24)
            }
        }
        .foregroundStyle(.white)
        .frame(minWidth: 820, minHeight: 560)
        .onAppear { permissions.refresh() }
        .onMoveCommand(perform: handleMove)
    }

    private var pageIndicator: some View {
        HStack(spacing: 7) {
            ForEach(OnboardingPage.allCases) { item in
                Capsule()
                    .fill(item == page ? Color.white.opacity(0.9) : Color.white.opacity(0.17))
                    .frame(width: item == page ? 22 : 7, height: 7)
            }
        }
        .animation(reduceMotion ? nil : MacEaseTheme.Motion.quick, value: page)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(page.rawValue + 1) of \(OnboardingPage.allCases.count)")
    }

    @ViewBuilder
    private var pageContent: some View {
        switch page {
        case .welcome:
            IntroPage(
                symbol: AppBrand.menuBarSymbol,
                eyebrow: page.eyebrow,
                title: "Welcome to \(AppBrand.name)",
                subtitle: AppBrand.tagline
            )
        case .screenshot:
            DemoPage(eyebrow: page.eyebrow, title: "Capture, then paste.", subtitle: "Select an area and it’s ready on your clipboard—with clear confirmation and no surprise files.") { ScreenshotDemo() }
        case .switcher:
            DemoPage(eyebrow: page.eyebrow, title: "Switch to the window you mean.", subtitle: "See individual windows, not just apps. Keyboard-first, with previews only while you need them.") { SwitcherDemo() }
        case .clipboard:
            DemoPage(eyebrow: page.eyebrow, title: "Find what you copied.", subtitle: "Search text, images, and file references in a bounded, local history you control.") { ClipboardDemo() }
        case .features:
            FeatureChoicePage(model: model)
        case .permissions:
            PermissionPage(permissions: permissions)
        case .ready:
            ReadyPage()
        }
    }

    private var footer: some View {
        HStack {
            if page != .welcome {
                Button("Back") { move(by: -1) }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white.opacity(0.72))
                    .keyboardShortcut(.leftArrow, modifiers: [])
            }
            Spacer()
            if page != .ready {
                Button("Skip") { finish() }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white.opacity(0.58))
            }
            Button(page == .ready ? "Done" : page == .welcome ? "Take the tour" : "Continue") {
                page == .ready ? finish() : move(by: 1)
            }
            .buttonStyle(.borderedProminent)
            .tint(MacEaseTheme.Colors.violet)
            .keyboardShortcut(.return, modifiers: [])
        }
    }

    private func handleMove(_ direction: MoveCommandDirection) {
        if direction == .left { move(by: -1) }
        if direction == .right { move(by: 1) }
    }

    private func move(by offset: Int) {
        let raw = min(max(page.rawValue + offset, 0), OnboardingPage.allCases.count - 1)
        guard let next = OnboardingPage(rawValue: raw) else { return }
        withAnimation(reduceMotion ? nil : MacEaseTheme.Motion.page) { page = next }
    }

    private func finish() {
        preferences.onboardingCompleted = true
        close()
    }
}

private struct IntroPage: View {
    let symbol: String
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 18) {
            Text(eyebrow).font(.caption.weight(.bold)).tracking(1.7).foregroundStyle(MacEaseTheme.Colors.cyan)
            BrandIcon(size: 96)
            Text(title).font(.system(size: 34, weight: .bold, design: .rounded))
            Text(subtitle).font(.title3).foregroundStyle(MacEaseTheme.Colors.secondaryText)
        }
    }
}

private struct DemoPage<Demo: View>: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    @ViewBuilder let demo: () -> Demo

    var body: some View {
        HStack(spacing: 48) {
            VStack(alignment: .leading, spacing: 15) {
                Text(eyebrow).font(.caption.weight(.bold)).tracking(1.7).foregroundStyle(MacEaseTheme.Colors.cyan)
                Text(title).font(.system(size: 29, weight: .bold, design: .rounded)).fixedSize(horizontal: false, vertical: true)
                Text(subtitle).font(.body).foregroundStyle(MacEaseTheme.Colors.secondaryText).lineSpacing(4).fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: 260, alignment: .leading)
            demo().frame(width: 410, height: 270)
        }
        .padding(.horizontal, 42)
    }
}

private struct FeatureChoicePage: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 20) {
            PageHeading(eyebrow: "MAKE IT YOURS", title: "Choose what works for you.", subtitle: "Each feature can be changed later. Turning one off also stops its background listeners and timers.")
            VStack(spacing: 0) {
                ChoiceToggle(title: "Screenshot → Paste", symbol: "camera.viewfinder", isOn: Binding(
                    get: { model.preferences.preferredScreenshot },
                    set: { model.setScreenshotEnabled($0) }
                ))
                Divider().overlay(.white.opacity(0.08)).padding(.leading, 52)
                ChoiceToggle(title: "Individual Window Switcher", symbol: "rectangle.3.group", isOn: Binding(
                    get: { model.preferences.preferredWindowSwitcher },
                    set: { model.setWindowSwitcherEnabled($0) }
                ))
                Divider().overlay(.white.opacity(0.08)).padding(.leading, 52)
                ChoiceToggle(title: "Clipboard History", symbol: "doc.on.clipboard", isOn: Binding(
                    get: { model.preferences.preferredClipboard },
                    set: { model.setClipboardEnabled($0) }
                ))
                Divider().overlay(.white.opacity(0.08)).padding(.leading, 52)
                ChoiceToggle(title: "Window Management", symbol: "rectangle.split.2x2", isOn: Binding(
                    get: { model.preferences.preferredWindowManagement },
                    set: { model.setWindowManagementEnabled($0) }
                ))
            }
            .padding(.horizontal, 8)
            .frame(width: 500)
            .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 18))
            .overlay { RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.10)) }
        }
    }
}

private struct ChoiceToggle: View {
    let title: String
    let symbol: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MacEaseTheme.Colors.cyan)
                    .frame(width: 28, height: 28)
                    .background(MacEaseTheme.Colors.blue.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))
                Text(title).font(.body.weight(.medium))
            }
        }
        .toggleStyle(.switch)
        .padding(.horizontal, 16)
        .frame(height: 51)
    }
}

private struct PermissionPage: View {
    @ObservedObject var permissions: PermissionCenter

    var body: some View {
        VStack(spacing: 20) {
            PageHeading(eyebrow: "YOUR CONTROL", title: "Permissions, only when needed.", subtitle: "Nothing is requested automatically. You can continue with reduced functionality and change access later.")
            VStack(spacing: 10) {
                PermissionRow(symbol: "accessibility", title: "Accessibility", reason: "Needed later to inspect and resize eligible windows.", state: permissions.accessibility, action: permissions.requestAccessibility)
                PermissionRow(symbol: "rectangle.dashed.badge.record", title: "Screen Recording", reason: "Needed later for screenshots and window previews.", state: permissions.screenRecording, action: permissions.requestScreenRecording)
            }
            .frame(width: 590)
        }
    }
}

private struct PermissionRow: View {
    let symbol: String
    let title: String
    let reason: String
    let state: PermissionState
    let action: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol).font(.title3).foregroundStyle(MacEaseTheme.Colors.cyan).frame(width: 30)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.body.weight(.semibold))
                Text(reason).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if state == .granted {
                Label("Granted", systemImage: "checkmark.circle.fill").font(.caption.weight(.semibold)).foregroundStyle(.green)
            } else {
                Button("Review…", action: action).buttonStyle(.bordered)
            }
        }
        .padding(15)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct ReadyPage: View {
    var body: some View {
        VStack(spacing: 17) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 50))
                .foregroundStyle(MacEaseTheme.Colors.cyan)
                .shadow(color: MacEaseTheme.Colors.blue.opacity(0.45), radius: 20)
            PageHeading(eyebrow: "ALL SET", title: "MacEase is ready.", subtitle: "It lives quietly in your menu bar. Reopen this tour or Settings at any time.")
            HStack(spacing: 10) {
                ShortcutHint(keys: ["⌥", "Tab"], label: "Window switcher")
                ShortcutHint(keys: ["⌘", "⇧", "V"], label: "Clipboard history")
            }
        }
    }
}

private struct PageHeading: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 10) {
            Text(eyebrow).font(.caption.weight(.bold)).tracking(1.7).foregroundStyle(MacEaseTheme.Colors.cyan)
            Text(title).font(.system(size: 28, weight: .bold, design: .rounded))
            Text(subtitle).font(.body).foregroundStyle(MacEaseTheme.Colors.secondaryText).multilineTextAlignment(.center).frame(maxWidth: 590)
        }
    }
}

private struct ShortcutHint: View {
    let keys: [String]
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(keys, id: \.self) { key in
                    Text(key).font(.system(size: 13, weight: .semibold, design: .rounded)).frame(minWidth: 25, minHeight: 25).background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                }
            }
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }
}
