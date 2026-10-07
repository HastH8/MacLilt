import AppKit
import Foundation

struct ShortcutSpec: Codable, Equatable, Hashable, Sendable {
    let key: String
    let modifiersRawValue: UInt

    init(key: String, modifiers: NSEvent.ModifierFlags) {
        self.key = key.lowercased()
        modifiersRawValue = modifiers.intersection(.deviceIndependentFlagsMask).rawValue
    }

    var modifiers: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: modifiersRawValue).intersection(.deviceIndependentFlagsMask)
    }

    func matches(event: NSEvent, allowingExtraModifiers extra: NSEvent.ModifierFlags = []) -> Bool {
        let eventKey = (event.charactersIgnoringModifiers ?? "").lowercased()
        let eventModifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        return eventKey == key && eventModifiers.subtracting(extra) == modifiers
    }

    var displayValue: String {
        let symbols = [
            (NSEvent.ModifierFlags.control, "⌃"),
            (.option, "⌥"),
            (.shift, "⇧"),
            (.command, "⌘")
        ].compactMap { modifiers.contains($0.0) ? $0.1 : nil }.joined()
        let keyName: String
        switch key {
        case "\t": keyName = "Tab"
        case " ": keyName = "Space"
        case "\r": keyName = "Return"
        default: keyName = key.uppercased()
        }
        return symbols + keyName
    }
}

enum ShortcutDefaults {
    static let screenshot = ShortcutSpec(key: "4", modifiers: [.control, .option])
    static let clipboard = ShortcutSpec(key: "v", modifiers: [.command, .shift])
    static let windowSwitcher = ShortcutSpec(key: "\t", modifiers: [.option])
}

enum ShortcutValidator {
    static func warning(for shortcut: ShortcutSpec, among allShortcuts: [ShortcutSpec]) -> String? {
        if allShortcuts.filter({ $0 == shortcut }).count > 1 {
            return "This shortcut is assigned to more than one MacEase action."
        }
        let reserved: [ShortcutSpec: String] = [
            ShortcutSpec(key: "\t", modifiers: [.command]): "Command-Tab is reserved by macOS.",
            ShortcutSpec(key: " ", modifiers: [.command]): "Command-Space is commonly used by Spotlight.",
            ShortcutSpec(key: "q", modifiers: [.command]): "Command-Q quits the active application.",
            ShortcutSpec(key: "3", modifiers: [.command, .shift]): "This is a standard macOS screenshot shortcut.",
            ShortcutSpec(key: "4", modifiers: [.command, .shift]): "This is a standard macOS screenshot shortcut.",
            ShortcutSpec(key: "5", modifiers: [.command, .shift]): "This is a standard macOS screenshot shortcut."
        ]
        return reserved[shortcut]
    }
}
