import AppKit

@MainActor
final class MiddleClickService {
    private let action: () -> Void
    private let excludedApplications: () -> Set<String>
    private var monitor: Any?

    init(action: @escaping () -> Void, excludedApplications: @escaping () -> Set<String>) {
        self.action = action
        self.excludedApplications = excludedApplications
    }

    func start() {
        guard monitor == nil else { return }
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .otherMouseDown) { [weak self] event in
            guard event.buttonNumber == 2 else { return }
            Task { @MainActor in self?.handle() }
        }
    }

    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }

    private func handle() {
        let frontmost = NSWorkspace.shared.frontmostApplication
        let identifiers = [frontmost?.bundleIdentifier, frontmost?.localizedName]
            .compactMap { $0?.lowercased() }
        guard excludedApplications().isDisjoint(with: identifiers) else { return }
        action()
    }
}
