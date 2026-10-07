import AppKit
@preconcurrency import ApplicationServices
import ScreenCaptureKit

@MainActor
final class WindowCatalog {
    func windows() -> [SwitchableWindow] {
        let workspace = NSWorkspace.shared
        let applications = Dictionary(uniqueKeysWithValues: workspace.runningApplications.map { ($0.processIdentifier, $0) })
        let frontPID = workspace.frontmostApplication?.processIdentifier
        let orderedWindowInfo = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
        var result: [SwitchableWindow] = []
        var seen = Set<String>()

        for info in orderedWindowInfo {
            guard (info[kCGWindowLayer as String] as? Int) == 0,
                  let pidValue = info[kCGWindowOwnerPID as String] as? Int,
                  let application = applications[pid_t(pidValue)],
                  application.activationPolicy == .regular,
                  application.bundleIdentifier != Bundle.main.bundleIdentifier else { continue }

            let axApplication = AXUIElementCreateApplication(pid_t(pidValue))
            var windowsValue: CFTypeRef?
            guard AXUIElementCopyAttributeValue(axApplication, kAXWindowsAttribute as CFString, &windowsValue) == .success,
                  let axWindows = windowsValue as? [AXUIElement] else { continue }

            let infoTitle = (info[kCGWindowName as String] as? String) ?? ""
            let match = axWindows.first { window in
                let title = stringAttribute(window, key: kAXTitleAttribute as String)
                return title == infoTitle || (infoTitle.isEmpty && !title.isEmpty)
            }
            guard let window = match else { continue }
            let identity = "\(pidValue)-\(CFHash(window))"
            guard seen.insert(identity).inserted else { continue }

            let minimized = boolAttribute(window, key: kAXMinimizedAttribute as String)
            guard !minimized else { continue }
            let title = stringAttribute(window, key: kAXTitleAttribute as String)
            let appName = application.localizedName ?? (info[kCGWindowOwnerName as String] as? String) ?? "Application"
            let icon = application.icon ?? NSImage(systemSymbolName: "app", accessibilityDescription: nil) ?? NSImage()
            result.append(SwitchableWindow(
                id: identity,
                processIdentifier: pid_t(pidValue),
                title: title.isEmpty ? "Untitled Window" : title,
                applicationName: appName,
                applicationIcon: icon,
                accessibilityElement: window,
                preview: nil
            ))
        }

        let frontmost = result.filter { $0.processIdentifier == frontPID }
        let remaining = result.filter { $0.processIdentifier != frontPID }
        return frontmost + remaining
    }

    func loadPreviews(for windows: [SwitchableWindow], maximumCount: Int = 8) async -> [String: NSImage] {
        guard CGPreflightScreenCaptureAccess() else { return [:] }
        guard let content = try? await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true) else { return [:] }
        var previews: [String: NSImage] = [:]

        for window in windows.prefix(maximumCount) {
            guard !Task.isCancelled,
                  let source = content.windows.first(where: {
                      $0.owningApplication?.processID == window.processIdentifier
                          && (($0.title ?? "") == window.title || window.title == "Untitled Window")
                  }) else { continue }
            let configuration = SCStreamConfiguration()
            let scale = min(320 / max(source.frame.width, 1), 220 / max(source.frame.height, 1), 1)
            configuration.width = max(1, Int(source.frame.width * scale))
            configuration.height = max(1, Int(source.frame.height * scale))
            configuration.showsCursor = false
            let filter = SCContentFilter(desktopIndependentWindow: source)
            if let image = try? await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration) {
                previews[window.id] = NSImage(cgImage: image, size: source.frame.size)
            }
        }
        return previews
    }

    func activate(_ window: SwitchableWindow) {
        NSRunningApplication(processIdentifier: window.processIdentifier)?.activate(options: [.activateAllWindows])
        AXUIElementPerformAction(window.accessibilityElement, kAXRaiseAction as CFString)
        AXUIElementSetAttributeValue(window.accessibilityElement, kAXMainAttribute as CFString, kCFBooleanTrue)
    }

    private func stringAttribute(_ element: AXUIElement, key: String) -> String {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, key as CFString, &value) == .success else { return "" }
        return value as? String ?? ""
    }

    private func boolAttribute(_ element: AXUIElement, key: String) -> Bool {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, key as CFString, &value) == .success else { return false }
        return value as? Bool ?? false
    }
}
