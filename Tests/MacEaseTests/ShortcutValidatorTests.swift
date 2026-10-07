import AppKit
import Testing
@testable import MacEase

@Suite("Shortcut validation")
struct ShortcutValidatorTests {
    @Test("Reserved shortcuts warn")
    func reservedShortcut() {
        let shortcut = ShortcutSpec(key: "\t", modifiers: [.command])
        #expect(ShortcutValidator.warning(for: shortcut, among: [shortcut]) != nil)
    }

    @Test("Duplicate shortcuts warn")
    func duplicateShortcut() {
        let shortcut = ShortcutSpec(key: "v", modifiers: [.command, .shift])
        #expect(ShortcutValidator.warning(for: shortcut, among: [shortcut, shortcut]) != nil)
    }

    @Test("Safe unique shortcut has no warning")
    func safeShortcut() {
        let shortcut = ShortcutSpec(key: "4", modifiers: [.control, .option])
        #expect(ShortcutValidator.warning(for: shortcut, among: [shortcut]) == nil)
    }
}
