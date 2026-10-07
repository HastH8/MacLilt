import Combine
import ServiceManagement

@MainActor
final class LaunchAtLoginService: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published private(set) var requiresApproval = false
    @Published private(set) var lastError: String?

    func refresh() {
        let status = SMAppService.mainApp.status
        isEnabled = status == .enabled
        requiresApproval = status == .requiresApproval
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
        refresh()
    }
}
