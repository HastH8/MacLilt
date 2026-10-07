import Combine
import Foundation

@MainActor
final class PreferenceStore: ObservableObject {
    static let standard = PreferenceStore(defaults: .standard)

    enum Key: String {
        case onboardingCompleted
        case preferredScreenshot
        case preferredWindowSwitcher
        case preferredClipboard
        case preferredWindowManagement
        case screenshotShortcut
        case clipboardShortcut
        case windowSwitcherShortcut
        case middleClickEnabled
        case middleClickExcludedApplications
        case saveScreenshots
        case clipboardItemLimit
        case clipboardRetentionDays
        case clipboardStorageLimitMB
        case clipboardPersistentHistory
        case clipboardExcludedApplications
    }

    private let defaults: UserDefaults

    @Published var onboardingCompleted: Bool {
        didSet { defaults.set(onboardingCompleted, forKey: Key.onboardingCompleted.rawValue) }
    }

    @Published var preferredScreenshot: Bool {
        didSet { defaults.set(preferredScreenshot, forKey: Key.preferredScreenshot.rawValue) }
    }

    @Published var preferredWindowSwitcher: Bool {
        didSet { defaults.set(preferredWindowSwitcher, forKey: Key.preferredWindowSwitcher.rawValue) }
    }

    @Published var preferredClipboard: Bool {
        didSet { defaults.set(preferredClipboard, forKey: Key.preferredClipboard.rawValue) }
    }

    @Published var preferredWindowManagement: Bool {
        didSet { defaults.set(preferredWindowManagement, forKey: Key.preferredWindowManagement.rawValue) }
    }

    @Published var screenshotShortcut: ShortcutSpec {
        didSet { save(screenshotShortcut, for: .screenshotShortcut) }
    }

    @Published var clipboardShortcut: ShortcutSpec {
        didSet { save(clipboardShortcut, for: .clipboardShortcut) }
    }

    @Published var windowSwitcherShortcut: ShortcutSpec {
        didSet { save(windowSwitcherShortcut, for: .windowSwitcherShortcut) }
    }

    @Published var middleClickEnabled: Bool {
        didSet { defaults.set(middleClickEnabled, forKey: Key.middleClickEnabled.rawValue) }
    }

    @Published var middleClickExcludedApplications: String {
        didSet { defaults.set(middleClickExcludedApplications, forKey: Key.middleClickExcludedApplications.rawValue) }
    }

    @Published var saveScreenshots: Bool {
        didSet { defaults.set(saveScreenshots, forKey: Key.saveScreenshots.rawValue) }
    }

    @Published var clipboardItemLimit: Int {
        didSet { defaults.set(clipboardItemLimit, forKey: Key.clipboardItemLimit.rawValue) }
    }

    @Published var clipboardRetentionDays: Int {
        didSet { defaults.set(clipboardRetentionDays, forKey: Key.clipboardRetentionDays.rawValue) }
    }

    @Published var clipboardStorageLimitMB: Int {
        didSet { defaults.set(clipboardStorageLimitMB, forKey: Key.clipboardStorageLimitMB.rawValue) }
    }

    @Published var clipboardPersistentHistory: Bool {
        didSet { defaults.set(clipboardPersistentHistory, forKey: Key.clipboardPersistentHistory.rawValue) }
    }

    @Published var clipboardExcludedApplications: String {
        didSet { defaults.set(clipboardExcludedApplications, forKey: Key.clipboardExcludedApplications.rawValue) }
    }

    init(defaults: UserDefaults) {
        self.defaults = defaults
        onboardingCompleted = defaults.bool(forKey: Key.onboardingCompleted.rawValue)

        let featureKeys: [Key] = [
            .preferredScreenshot,
            .preferredWindowSwitcher,
            .preferredClipboard,
            .preferredWindowManagement
        ]
        let hasFeatureChoice = featureKeys.contains { defaults.object(forKey: $0.rawValue) != nil }
        preferredScreenshot = hasFeatureChoice ? defaults.bool(forKey: Key.preferredScreenshot.rawValue) : true
        preferredWindowSwitcher = hasFeatureChoice ? defaults.bool(forKey: Key.preferredWindowSwitcher.rawValue) : true
        preferredClipboard = hasFeatureChoice ? defaults.bool(forKey: Key.preferredClipboard.rawValue) : true
        preferredWindowManagement = hasFeatureChoice ? defaults.bool(forKey: Key.preferredWindowManagement.rawValue) : true
        screenshotShortcut = Self.load(ShortcutSpec.self, key: .screenshotShortcut, defaults: defaults) ?? ShortcutDefaults.screenshot
        clipboardShortcut = Self.load(ShortcutSpec.self, key: .clipboardShortcut, defaults: defaults) ?? ShortcutDefaults.clipboard
        windowSwitcherShortcut = Self.load(ShortcutSpec.self, key: .windowSwitcherShortcut, defaults: defaults) ?? ShortcutDefaults.windowSwitcher
        middleClickEnabled = defaults.bool(forKey: Key.middleClickEnabled.rawValue)
        middleClickExcludedApplications = defaults.string(forKey: Key.middleClickExcludedApplications.rawValue) ?? ""
        saveScreenshots = defaults.bool(forKey: Key.saveScreenshots.rawValue)
        clipboardItemLimit = defaults.object(forKey: Key.clipboardItemLimit.rawValue) == nil ? 100 : defaults.integer(forKey: Key.clipboardItemLimit.rawValue)
        clipboardRetentionDays = defaults.object(forKey: Key.clipboardRetentionDays.rawValue) == nil ? 30 : defaults.integer(forKey: Key.clipboardRetentionDays.rawValue)
        clipboardStorageLimitMB = defaults.object(forKey: Key.clipboardStorageLimitMB.rawValue) == nil ? 100 : defaults.integer(forKey: Key.clipboardStorageLimitMB.rawValue)
        clipboardPersistentHistory = defaults.object(forKey: Key.clipboardPersistentHistory.rawValue) == nil ? true : defaults.bool(forKey: Key.clipboardPersistentHistory.rawValue)
        clipboardExcludedApplications = defaults.string(forKey: Key.clipboardExcludedApplications.rawValue) ?? ""
    }

    func restoreShortcutDefaults() {
        screenshotShortcut = ShortcutDefaults.screenshot
        clipboardShortcut = ShortcutDefaults.clipboard
        windowSwitcherShortcut = ShortcutDefaults.windowSwitcher
    }

    private func save<T: Encodable>(_ value: T, for key: Key) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key.rawValue)
    }

    private static func load<T: Decodable>(_ type: T.Type, key: Key, defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key.rawValue) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
