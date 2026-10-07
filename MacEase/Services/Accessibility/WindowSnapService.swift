import AppKit

@MainActor
final class WindowSnapService {
    private let windowManagement: WindowManagementService
    private let preview: SnapPreviewCoordinator
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var pendingLayout: WindowLayout?
    private var lastUpdate = ContinuousClock.now

    init(windowManagement: WindowManagementService, preview: SnapPreviewCoordinator = SnapPreviewCoordinator()) {
        self.windowManagement = windowManagement
        self.preview = preview
    }

    func start() {
        guard globalMonitor == nil, localMonitor == nil else { return }
        let mask: NSEvent.EventTypeMask = [.leftMouseDragged, .leftMouseUp]
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
            Task { @MainActor in self?.handle(event) }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handle(event)
            return event
        }
    }

    func stop() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
        pendingLayout = nil
        preview.hide()
    }

    private func handle(_ event: NSEvent) {
        if event.type == .leftMouseUp {
            let layout = pendingLayout
            pendingLayout = nil
            preview.hide()
            if let layout { try? windowManagement.apply(layout) }
            return
        }

        guard !event.modifierFlags.contains(.command) else {
            pendingLayout = nil
            preview.hide()
            return
        }
        let now = ContinuousClock.now
        guard lastUpdate.duration(to: now) >= .milliseconds(30) else { return }
        lastUpdate = now

        let location = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(location) }),
              let layout = SnapTargetResolver.layout(at: location, in: screen.visibleFrame),
              let frame = WindowGeometry.frame(for: layout, in: screen.visibleFrame, currentFrame: screen.visibleFrame) else {
            pendingLayout = nil
            preview.hide()
            return
        }
        pendingLayout = layout
        preview.show(frame: frame, layout: layout)
    }
}
