import Foundation
import Testing
@testable import MacEase

@Suite("Preference persistence")
@MainActor
struct PreferenceStoreTests {
    @Test("Feature choices default on and persist")
    func choicesPersist() throws {
        let suite = "MacEaseTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = PreferenceStore(defaults: defaults)
        #expect(store.preferredScreenshot)
        store.preferredScreenshot = false

        let reloaded = PreferenceStore(defaults: defaults)
        #expect(!reloaded.preferredScreenshot)
    }

    @Test("Onboarding completion persists")
    func onboardingPersists() throws {
        let suite = "MacEaseTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = PreferenceStore(defaults: defaults)
        #expect(!store.onboardingCompleted)
        store.onboardingCompleted = true
        #expect(PreferenceStore(defaults: defaults).onboardingCompleted)
    }
}
