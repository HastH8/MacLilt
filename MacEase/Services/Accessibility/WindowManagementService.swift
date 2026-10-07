import AppKit
@preconcurrency import ApplicationServices
import Combine

enum WindowManagementError: LocalizedError {
    case permissionRequired
    case noFocusedWindow
    case unsupportedWindow
    case fullscreenWindow
    case noScreen
    case accessibility(AXError)

    var errorDescription: String? {
        switch self {
        case .permissionRequired: "Accessibility permission is required."
        case .noFocusedWindow: "No adjustable window is focused."
        case .unsupportedWindow: "This window does not support resizing."
        case .fullscreenWindow: "Exit full screen before resizing this window."
        case .noScreen: "No matching display was found."
        case .accessibility(let error): "Accessibility returned error \(error.rawValue)."
        }
    }
}

@MainActor
final class WindowManagementService: ObservableObject {
    private var previousFrames: [CFHashCode: CGRect] = [:]

    func apply(_ layout: WindowLayout) throws {
        guard AXIsProcessTrusted() else { throw WindowManagementError.permissionRequired }
        let window = try focusedWindow()
        let isFullScreen = try boolAttribute(window, key: "AXFullScreen")
        guard !isFullScreen else {
            throw WindowManagementError.fullscreenWindow
        }
        let currentAXFrame = try frame(of: window)
        let currentFrame = ScreenCoordinates.appKitRect(fromAX: currentAXFrame)
        guard let screen = screen(containing: currentFrame) else { throw WindowManagementError.noScreen }
        let identity = CFHash(window)

        switch layout {
        case .restore:
            guard let previous = previousFrames.removeValue(forKey: identity) else {
                throw WindowManagementError.unsupportedWindow
            }
            try set(frame: ScreenCoordinates.axRect(fromAppKit: previous), for: window)
        case .nextDisplay:
            guard let index = NSScreen.screens.firstIndex(of: screen), NSScreen.screens.count > 1 else {
                throw WindowManagementError.noScreen
            }
            previousFrames[identity] = currentFrame
            let next = NSScreen.screens[(index + 1) % NSScreen.screens.count]
            let target = WindowGeometry.translatedFrame(currentFrame, from: screen.visibleFrame, to: next.visibleFrame)
            try set(frame: ScreenCoordinates.axRect(fromAppKit: target), for: window)
        default:
            guard let target = WindowGeometry.frame(for: layout, in: screen.visibleFrame, currentFrame: currentFrame) else {
                throw WindowManagementError.unsupportedWindow
            }
            if previousFrames[identity] == nil { previousFrames[identity] = currentFrame }
            try set(frame: ScreenCoordinates.axRect(fromAppKit: target), for: window)
        }
    }

    private func focusedWindow() throws -> AXUIElement {
        let system = AXUIElementCreateSystemWide()
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(system, kAXFocusedWindowAttribute as CFString, &value)
        guard error == .success, let window = value as! AXUIElement? else {
            throw error == .success ? WindowManagementError.noFocusedWindow : .accessibility(error)
        }
        return window
    }

    private func frame(of window: AXUIElement) throws -> CGRect {
        var positionValue: CFTypeRef?
        var sizeValue: CFTypeRef?
        let positionError = AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue)
        let sizeError = AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue)
        guard positionError == .success, sizeError == .success,
              let positionAX = positionValue as! AXValue?,
              let sizeAX = sizeValue as! AXValue? else {
            throw WindowManagementError.unsupportedWindow
        }
        var position = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(positionAX, .cgPoint, &position),
              AXValueGetValue(sizeAX, .cgSize, &size) else {
            throw WindowManagementError.unsupportedWindow
        }
        return CGRect(origin: position, size: size)
    }

    private func set(frame: CGRect, for window: AXUIElement) throws {
        var positionSettable = DarwinBoolean(false)
        var sizeSettable = DarwinBoolean(false)
        AXUIElementIsAttributeSettable(window, kAXPositionAttribute as CFString, &positionSettable)
        AXUIElementIsAttributeSettable(window, kAXSizeAttribute as CFString, &sizeSettable)
        guard positionSettable.boolValue, sizeSettable.boolValue else { throw WindowManagementError.unsupportedWindow }

        var position = frame.origin
        var size = frame.size
        guard let positionValue = AXValueCreate(.cgPoint, &position),
              let sizeValue = AXValueCreate(.cgSize, &size) else {
            throw WindowManagementError.unsupportedWindow
        }
        let positionError = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
        let sizeError = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        guard positionError == .success, sizeError == .success else {
            throw WindowManagementError.accessibility(positionError != .success ? positionError : sizeError)
        }
    }

    private func boolAttribute(_ element: AXUIElement, key: String) throws -> Bool {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, key as CFString, &value)
        if error == .noValue || error == .attributeUnsupported { return false }
        guard error == .success else { throw WindowManagementError.accessibility(error) }
        return (value as? Bool) ?? false
    }

    private func screen(containing frame: CGRect) -> NSScreen? {
        let center = CGPoint(x: frame.midX, y: frame.midY)
        return NSScreen.screens.first(where: { $0.frame.contains(center) })
            ?? NSScreen.screens.max(by: { $0.frame.intersection(frame).area < $1.frame.intersection(frame).area })
    }
}

enum ScreenCoordinates {
    static func axRect(fromAppKit rect: CGRect, screens: [NSScreen] = NSScreen.screens) -> CGRect {
        let referenceY = screens.first?.frame.maxY ?? 0
        return CGRect(x: rect.minX, y: referenceY - rect.maxY, width: rect.width, height: rect.height)
    }

    static func appKitRect(fromAX rect: CGRect, screens: [NSScreen] = NSScreen.screens) -> CGRect {
        let referenceY = screens.first?.frame.maxY ?? 0
        return CGRect(x: rect.minX, y: referenceY - rect.maxY, width: rect.width, height: rect.height)
    }
}

private extension CGRect {
    var area: CGFloat { isNull ? 0 : width * height }
}
