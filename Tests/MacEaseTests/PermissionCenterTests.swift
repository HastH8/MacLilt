import Testing
@testable import MacEase

private final class PermissionCheckerSpy: PermissionChecking {
    var accessibility = false
    var screenCapture = false
    private(set) var accessibilityPrompts: [Bool] = []
    private(set) var captureRequests = 0

    func accessibilityIsTrusted(prompt: Bool) -> Bool {
        accessibilityPrompts.append(prompt)
        return accessibility
    }

    func screenCaptureIsAllowed() -> Bool { screenCapture }

    func requestScreenCapture() -> Bool {
        captureRequests += 1
        return screenCapture
    }
}

@Suite("Permission state transitions")
@MainActor
struct PermissionCenterTests {
    @Test("Refresh never prompts")
    func refreshDoesNotPrompt() {
        let checker = PermissionCheckerSpy()
        let center = PermissionCenter(checker: checker)

        center.refresh()

        #expect(checker.accessibilityPrompts == [false])
        #expect(checker.captureRequests == 0)
        #expect(center.accessibility == .notGranted)
    }

    @Test("Explicit requests update state")
    func explicitRequests() {
        let checker = PermissionCheckerSpy()
        checker.accessibility = true
        checker.screenCapture = true
        let center = PermissionCenter(checker: checker)

        center.requestAccessibility()
        center.requestScreenRecording()

        #expect(checker.accessibilityPrompts == [true])
        #expect(checker.captureRequests == 1)
        #expect(center.accessibility == .granted)
        #expect(center.screenRecording == .granted)
    }
}
