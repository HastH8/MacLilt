import AppKit
@preconcurrency import ApplicationServices
import Combine
import CoreGraphics

enum PermissionState: Equatable {
    case granted
    case notGranted

    var title: String {
        switch self {
        case .granted: "Granted"
        case .notGranted: "Not granted"
        }
    }
}

protocol PermissionChecking {
    func accessibilityIsTrusted(prompt: Bool) -> Bool
    func screenCaptureIsAllowed() -> Bool
    func requestScreenCapture() -> Bool
}

struct SystemPermissionChecker: PermissionChecking {
    func accessibilityIsTrusted(prompt: Bool) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    func screenCaptureIsAllowed() -> Bool {
        CGPreflightScreenCaptureAccess()
    }

    func requestScreenCapture() -> Bool {
        CGRequestScreenCaptureAccess()
    }
}

@MainActor
final class PermissionCenter: ObservableObject {
    @Published private(set) var accessibility: PermissionState = .notGranted
    @Published private(set) var screenRecording: PermissionState = .notGranted

    private let checker: PermissionChecking

    init(checker: PermissionChecking = SystemPermissionChecker()) {
        self.checker = checker
    }

    func refresh() {
        accessibility = checker.accessibilityIsTrusted(prompt: false) ? .granted : .notGranted
        screenRecording = checker.screenCaptureIsAllowed() ? .granted : .notGranted
    }

    func requestAccessibility() {
        accessibility = checker.accessibilityIsTrusted(prompt: true) ? .granted : .notGranted
    }

    func requestScreenRecording() {
        screenRecording = checker.requestScreenCapture() ? .granted : .notGranted
    }
}
