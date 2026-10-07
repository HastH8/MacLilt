import AppKit
import Combine
import Foundation

enum DashboardRoute: Equatable {
    case home
    case settings
}

@MainActor
final class AppModel: ObservableObject {
    let preferences: PreferenceStore
    let permissions: PermissionCenter
    let launchAtLogin: LaunchAtLoginService
    let screenshotService: ScreenshotService
    let clipboardMonitor: ClipboardMonitor
    let toast: ToastWindowCoordinator
    let windowManagement: WindowManagementService
    let windowSwitcher: WindowSwitcherCoordinator
    let windowSnap: WindowSnapService
    let finderService: FinderService
    private lazy var middleClickService = MiddleClickService(
        action: { [weak self] in self?.showClipboardHistory() },
        excludedApplications: { [weak self] in
            Set((self?.preferences.middleClickExcludedApplications ?? "")
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                .filter { !$0.isEmpty })
        }
    )

    private lazy var clipboardWindow = ClipboardHistoryWindowCoordinator(monitor: clipboardMonitor, toast: toast)
    private lazy var shortcutMonitor = GlobalShortcutMonitor(handlers: .init(
        screenshot: { [weak self] in self?.captureScreenshot() },
        clipboard: { [weak self] in self?.showClipboardHistory() },
        switcherCycle: { [weak self] reverse in self?.showWindowSwitcher(reverse: reverse) },
        switcherMove: { [weak self] offset in self?.windowSwitcher.move(by: offset) },
        switcherCommit: { [weak self] in self?.windowSwitcher.commit() },
        switcherCancel: { [weak self] in self?.windowSwitcher.cancel() },
        windowLayout: { [weak self] layout in self?.applyWindowLayout(layout) },
        isSwitcherVisible: { [weak self] in self?.windowSwitcher.isVisible == true },
        screenshotEnabled: { [weak self] in self?.preferences.preferredScreenshot == true },
        clipboardEnabled: { [weak self] in self?.preferences.preferredClipboard == true },
        switcherEnabled: { [weak self] in self?.preferences.preferredWindowSwitcher == true },
        windowManagementEnabled: { [weak self] in self?.preferences.preferredWindowManagement == true },
        screenshotShortcut: { [weak self] in self?.preferences.screenshotShortcut ?? ShortcutDefaults.screenshot },
        clipboardShortcut: { [weak self] in self?.preferences.clipboardShortcut ?? ShortcutDefaults.clipboard },
        switcherShortcut: { [weak self] in self?.preferences.windowSwitcherShortcut ?? ShortcutDefaults.windowSwitcher }
    ))

    @Published var dashboardRoute: DashboardRoute = .home

    var showOnboarding: () -> Void = {}
    var presentDashboard: () -> Void = {}

    init(
        preferences: PreferenceStore? = nil,
        permissions: PermissionCenter? = nil,
        launchAtLogin: LaunchAtLoginService? = nil,
        screenshotService: ScreenshotService? = nil,
        clipboardMonitor: ClipboardMonitor? = nil,
        toast: ToastWindowCoordinator? = nil,
        windowManagement: WindowManagementService? = nil,
        windowSwitcher: WindowSwitcherCoordinator? = nil
    ) {
        self.preferences = preferences ?? .standard
        self.permissions = permissions ?? PermissionCenter()
        self.launchAtLogin = launchAtLogin ?? LaunchAtLoginService()
        self.screenshotService = screenshotService ?? ScreenshotService()
        self.clipboardMonitor = clipboardMonitor ?? ClipboardMonitor()
        self.toast = toast ?? ToastWindowCoordinator()
        self.windowManagement = windowManagement ?? WindowManagementService()
        self.windowSwitcher = windowSwitcher ?? WindowSwitcherCoordinator()
        self.windowSnap = WindowSnapService(windowManagement: self.windowManagement)
        self.finderService = FinderService()
        syncFeatureLifecycles()
    }

    func refreshSystemState() {
        permissions.refresh()
        launchAtLogin.refresh()
    }

    func showDashboard() {
        dashboardRoute = .home
        presentDashboard()
    }

    func showSettings() {
        dashboardRoute = .settings
        refreshSystemState()
        presentDashboard()
    }

    func syncFeatureLifecycles() {
        syncClipboardConfiguration()
        if preferences.preferredClipboard {
            clipboardMonitor.start()
        } else {
            clipboardMonitor.stop()
        }
        if preferences.preferredScreenshot || preferences.preferredClipboard || preferences.preferredWindowSwitcher || preferences.preferredWindowManagement {
            shortcutMonitor.start()
        } else {
            shortcutMonitor.stop()
        }
        if preferences.preferredWindowManagement {
            windowSnap.start()
        } else {
            windowSnap.stop()
        }
        if preferences.middleClickEnabled {
            middleClickService.start()
        } else {
            middleClickService.stop()
        }
    }

    func syncClipboardConfiguration() {
        clipboardMonitor.configure(
            itemLimit: preferences.clipboardItemLimit,
            retentionDays: preferences.clipboardRetentionDays,
            storageLimitMB: preferences.clipboardStorageLimitMB,
            persistent: preferences.clipboardPersistentHistory,
            excludedApplications: preferences.clipboardExcludedApplications
        )
    }

    func setClipboardEnabled(_ enabled: Bool) {
        preferences.preferredClipboard = enabled
        syncFeatureLifecycles()
    }

    func setScreenshotEnabled(_ enabled: Bool) {
        preferences.preferredScreenshot = enabled
        syncFeatureLifecycles()
    }

    func setWindowSwitcherEnabled(_ enabled: Bool) {
        preferences.preferredWindowSwitcher = enabled
        if !enabled { windowSwitcher.cancel() }
        syncFeatureLifecycles()
    }

    func setWindowManagementEnabled(_ enabled: Bool) {
        preferences.preferredWindowManagement = enabled
        syncFeatureLifecycles()
    }

    func setMiddleClickEnabled(_ enabled: Bool) {
        preferences.middleClickEnabled = enabled
        syncFeatureLifecycles()
    }

    func showClipboardHistory() {
        clipboardWindow.show()
    }

    func captureScreenshot(_ mode: ScreenshotMode = .area) {
        Task {
            switch await screenshotService.capture(mode) {
            case .copied:
                if preferences.saveScreenshots, let url = await screenshotService.saveCurrentClipboardImage() {
                    toast.show(message: "Copied and saved to \(url.lastPathComponent)", symbol: "checkmark.circle.fill")
                } else {
                    toast.show(message: "Screenshot copied", symbol: "checkmark.circle.fill")
                }
            case .cancelled:
                break
            case .failed(let message):
                toast.show(message: message, symbol: "exclamationmark.triangle.fill", isError: true)
            }
        }
    }

    func showWindowSwitcher(reverse: Bool = false) {
        guard permissions.accessibility == .granted else {
            toast.show(message: "Grant Accessibility access for window switching", symbol: "hand.raised.fill", isError: true)
            return
        }
        windowSwitcher.showAndCycle(reverse: reverse)
    }

    func applyWindowLayout(_ layout: WindowLayout) {
        do {
            try windowManagement.apply(layout)
            toast.show(message: layout.title, symbol: layout.symbol)
        } catch {
            toast.show(message: error.localizedDescription, symbol: "exclamationmark.triangle.fill", isError: true)
        }
    }

    func shutdown() {
        shortcutMonitor.stop()
        clipboardMonitor.stop()
        windowSnap.stop()
        middleClickService.stop()
        windowSwitcher.cancel()
    }

    func copyFinderPaths() {
        Task {
            do {
                let count = try await finderService.copySelectedPaths()
                toast.show(message: count == 1 ? "Path copied" : "\(count) paths copied", symbol: "link")
            } catch {
                toast.show(message: error.localizedDescription, symbol: "exclamationmark.triangle.fill", isError: true)
            }
        }
    }

    func copyFinderFileReferences() {
        Task {
            do {
                let count = try await finderService.copySelectedFileReferences()
                toast.show(message: count == 1 ? "File copied" : "\(count) files copied", symbol: "doc.on.doc")
            } catch {
                toast.show(message: error.localizedDescription, symbol: "exclamationmark.triangle.fill", isError: true)
            }
        }
    }

    func createNewFinderFile() {
        Task {
            do {
                if let url = try await finderService.createNewFile() {
                    toast.show(message: "Created \(url.lastPathComponent)", symbol: "doc.badge.plus")
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
            } catch {
                toast.show(message: error.localizedDescription, symbol: "exclamationmark.triangle.fill", isError: true)
            }
        }
    }

    func revealClipboardFiles() {
        do {
            let count = try finderService.revealClipboardFiles()
            toast.show(message: count == 1 ? "Revealed file" : "Revealed \(count) files", symbol: "folder")
        } catch {
            toast.show(message: error.localizedDescription, symbol: "exclamationmark.triangle.fill", isError: true)
        }
    }
}
