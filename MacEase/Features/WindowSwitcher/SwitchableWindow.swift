import AppKit
@preconcurrency import ApplicationServices

@MainActor
struct SwitchableWindow: Identifiable {
    let id: String
    let processIdentifier: pid_t
    let title: String
    let applicationName: String
    let applicationIcon: NSImage
    let accessibilityElement: AXUIElement
    var preview: NSImage?
}
