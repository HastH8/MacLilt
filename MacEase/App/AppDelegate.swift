import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appModel = AppModel()
    private var onboardingCoordinator: OnboardingWindowCoordinator?
    private var dashboardCoordinator: DashboardWindowCoordinator?
    private var activeObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // MacEase is intentionally a regular app as well as a menu-bar utility.
        // This keeps a persistent Dock icon users can click after an action moves
        // focus to another application.
        NSApp.setActivationPolicy(.regular)

        let coordinator = OnboardingWindowCoordinator(model: appModel)
        onboardingCoordinator = coordinator
        let dashboard = DashboardWindowCoordinator(model: appModel)
        dashboardCoordinator = dashboard
        appModel.showOnboarding = { [weak coordinator] in
            coordinator?.show()
        }
        appModel.presentDashboard = { [weak dashboard] in
            dashboard?.show()
        }

        activeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.appModel.refreshSystemState() }
        }

        appModel.refreshSystemState()
        if !appModel.preferences.onboardingCompleted {
            DispatchQueue.main.async { coordinator.show() }
        } else {
            DispatchQueue.main.async { dashboard.show() }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        appModel.shutdown()
        if let activeObserver {
            NotificationCenter.default.removeObserver(activeObserver)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if appModel.preferences.onboardingCompleted {
            dashboardCoordinator?.show()
        } else {
            onboardingCoordinator?.show()
        }
        return true
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }
}
