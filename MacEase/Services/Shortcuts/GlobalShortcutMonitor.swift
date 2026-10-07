import AppKit

@MainActor
final class GlobalShortcutMonitor {
    struct Handlers {
        let screenshot: () -> Void
        let clipboard: () -> Void
        let switcherCycle: (_ reverse: Bool) -> Void
        let switcherMove: (_ offset: Int) -> Void
        let switcherCommit: () -> Void
        let switcherCancel: () -> Void
        let windowLayout: (_ layout: WindowLayout) -> Void
        let isSwitcherVisible: () -> Bool
        let screenshotEnabled: () -> Bool
        let clipboardEnabled: () -> Bool
        let switcherEnabled: () -> Bool
        let windowManagementEnabled: () -> Bool
        let screenshotShortcut: () -> ShortcutSpec
        let clipboardShortcut: () -> ShortcutSpec
        let switcherShortcut: () -> ShortcutSpec
    }

    private let handlers: Handlers
    private var globalMonitor: Any?
    private var localMonitor: Any?

    init(handlers: Handlers) {
        self.handlers = handlers
    }

    func start() {
        guard globalMonitor == nil, localMonitor == nil else { return }
        let mask: NSEvent.EventTypeMask = [.keyDown, .flagsChanged]
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
            Task { @MainActor in _ = self?.handle(event) }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handle(event) == true ? nil : event
        }
    }

    func stop() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
    }

    @discardableResult
    private func handle(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        if event.type == .flagsChanged, handlers.isSwitcherVisible(), !flags.contains(.option) {
            handlers.switcherCommit()
            return true
        }
        guard event.type == .keyDown else { return false }

        if handlers.isSwitcherVisible() {
            switch event.keyCode {
            case 53:
                handlers.switcherCancel()
                return true
            case 123:
                handlers.switcherMove(-1)
                return true
            case 124:
                handlers.switcherMove(1)
                return true
            case _ where handlers.switcherShortcut().matches(event: event, allowingExtraModifiers: .shift):
                handlers.switcherCycle(flags.contains(.shift))
                return true
            default:
                break
            }
        }

        if handlers.switcherShortcut().matches(event: event, allowingExtraModifiers: .shift), handlers.switcherEnabled() {
            handlers.switcherCycle(flags.contains(.shift))
            return true
        }
        if handlers.clipboardShortcut().matches(event: event), handlers.clipboardEnabled() {
            handlers.clipboard()
            return true
        }
        if handlers.screenshotShortcut().matches(event: event), handlers.screenshotEnabled() {
            handlers.screenshot()
            return true
        }
        if flags.contains([.control, .option]), handlers.windowManagementEnabled() {
            switch event.keyCode {
            case 123: handlers.windowLayout(.leftHalf); return true
            case 124: handlers.windowLayout(.rightHalf); return true
            case 126: handlers.windowLayout(.maximize); return true
            case 125: handlers.windowLayout(.restore); return true
            default: break
            }
        }
        return false
    }
}
