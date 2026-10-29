//
//  AppPreferencesTests.swift
//  MagicTricksTests
//

import XCTest
@testable import MagicTricks

final class AppPreferencesTests: XCTestCase {

    func test_emptyStore_returnsDefaultForEveryProperty() {
        let preferences = AppPreferences(store: MockPreferenceStore())

        XCTAssertEqual(preferences.hapticSpeedMultiplier, AppPreferences.Default.hapticSpeedMultiplier)
        XCTAssertEqual(preferences.isHapticGroupByThreeEnabled, AppPreferences.Default.hapticGroupByThreeEnabled)
        XCTAssertEqual(preferences.hapticIntensity, AppPreferences.Default.hapticIntensity)
        XCTAssertEqual(preferences.isSecretGestureEnabled, AppPreferences.Default.secretGestureEnabled)
        XCTAssertEqual(preferences.screenDownHoldDuration, AppPreferences.Default.screenDownHoldDuration)
        XCTAssertEqual(preferences.isExitHintEnabled, AppPreferences.Default.isExitHintEnabled)
        XCTAssertEqual(preferences.usesStandardMagicGallerySet, AppPreferences.Default.usesStandardMagicGallerySet)
    }

    func test_hapticSpeedMultiplier_clampsToRange() {
        let preferences = AppPreferences(store: MockPreferenceStore())

        preferences.hapticSpeedMultiplier = 5.0
        XCTAssertEqual(preferences.hapticSpeedMultiplier, AppPreferences.Range.hapticSpeedMultiplier.upperBound)

        preferences.hapticSpeedMultiplier = 0.0
        XCTAssertEqual(preferences.hapticSpeedMultiplier, AppPreferences.Range.hapticSpeedMultiplier.lowerBound)
    }

    func test_screenDownHoldDuration_clampsToRange() {
        let preferences = AppPreferences(store: MockPreferenceStore())

        preferences.screenDownHoldDuration = 5.0
        XCTAssertEqual(preferences.screenDownHoldDuration, AppPreferences.Range.screenDownHoldDuration.upperBound)

        preferences.screenDownHoldDuration = 0.0
        XCTAssertEqual(preferences.screenDownHoldDuration, AppPreferences.Range.screenDownHoldDuration.lowerBound)
    }

    func test_hapticIntensity_roundTripsThroughStore() {
        let preferences = AppPreferences(store: MockPreferenceStore())

        for intensity: HapticIntensity in [.light, .medium, .heavy] {
            preferences.hapticIntensity = intensity
            XCTAssertEqual(preferences.hapticIntensity, intensity)
        }
    }

    func test_integerPreferences_roundTripAsIntegers() {
        let store = MockPreferenceStore()
        let preferences = AppPreferences(store: store)

        preferences.trickLaunchCount = 7

        XCTAssertEqual(preferences.trickLaunchCount, 7)
        XCTAssertEqual(store.storage[AppPreferences.Key.trickLaunchCount] as? Int, 7)
    }

    func test_integerPreferences_readValuesPreviouslyStoredAsDouble() {
        let store = MockPreferenceStore()
        store.storage[AppPreferences.Key.trickLaunchCount] = 5.0
        let preferences = AppPreferences(store: store)

        XCTAssertEqual(preferences.trickLaunchCount, 5)
    }

    func test_migrateIfNeeded_migratesLegacyUsesStandardMagicGallerySetValue() {
        let store = MockPreferenceStore()
        store.storage["ImpossibleGalleryUsesStandardSet"] = false
        let preferences = AppPreferences(store: store)

        preferences.migrateIfNeeded()

        XCTAssertEqual(preferences.usesStandardMagicGallerySet, false)
        XCTAssertEqual(store.storage[AppPreferences.Key.preferencesSchemaVersion] as? Int, 1)
    }

    func test_migrateIfNeeded_withNoLegacyKey_keepsDefaultAndBumpsSchemaVersion() {
        let store = MockPreferenceStore()
        let preferences = AppPreferences(store: store)

        preferences.migrateIfNeeded()

        XCTAssertEqual(preferences.usesStandardMagicGallerySet, AppPreferences.Default.usesStandardMagicGallerySet)
        XCTAssertEqual(store.storage[AppPreferences.Key.preferencesSchemaVersion] as? Int, 1)
    }

    func test_migrateIfNeeded_secondCallDoesNotOverrideValueSetAfterFirstMigration() {
        let store = MockPreferenceStore()
        store.storage["ImpossibleGalleryUsesStandardSet"] = false
        let preferences = AppPreferences(store: store)
        preferences.migrateIfNeeded()

        preferences.usesStandardMagicGallerySet = true
        preferences.migrateIfNeeded()

        XCTAssertEqual(preferences.usesStandardMagicGallerySet, true)
    }
}

// The same preference rules against a real UserDefaults suite, so a mock that drifts from the real store can't hide a bug.
final class AppPreferencesOnRealDefaultsTests: XCTestCase {

    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "MagicTricksTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func test_migrateIfNeeded_carriesTheLegacyGallerySetValueOver() {
        defaults.set(false, forKey: "ImpossibleGalleryUsesStandardSet")
        let preferences = AppPreferences(store: defaults)

        preferences.migrateIfNeeded()

        XCTAssertEqual(preferences.usesStandardMagicGallerySet, false)
        XCTAssertEqual(defaults.integer(forKey: AppPreferences.Key.preferencesSchemaVersion), 1)
    }

    func test_migrateIfNeeded_onAFreshStore_keepsTheDefaultAndMarksTheSchemaVersion() {
        let preferences = AppPreferences(store: defaults)

        preferences.migrateIfNeeded()

        XCTAssertEqual(preferences.usesStandardMagicGallerySet, AppPreferences.Default.usesStandardMagicGallerySet)
        XCTAssertEqual(defaults.integer(forKey: AppPreferences.Key.preferencesSchemaVersion), 1)
    }

    func test_migrateIfNeeded_runsOnlyOnce() {
        defaults.set(false, forKey: "ImpossibleGalleryUsesStandardSet")
        let preferences = AppPreferences(store: defaults)
        preferences.migrateIfNeeded()

        preferences.usesStandardMagicGallerySet = true
        preferences.migrateIfNeeded()

        XCTAssertEqual(preferences.usesStandardMagicGallerySet, true)
    }

    func test_integerPreferences_readValuesPreviouslyStoredAsDouble() {
        defaults.set(5.0, forKey: AppPreferences.Key.trickLaunchCount)
        let preferences = AppPreferences(store: defaults)

        XCTAssertEqual(preferences.trickLaunchCount, 5)
    }

    func test_unsetKeys_fallBackToTheDefaults() {
        let preferences = AppPreferences(store: defaults)

        XCTAssertEqual(preferences.hapticIntensity, AppPreferences.Default.hapticIntensity)
        XCTAssertEqual(preferences.hapticSpeedMultiplier, AppPreferences.Default.hapticSpeedMultiplier)
        XCTAssertEqual(preferences.usesStandardMagicGallerySet, AppPreferences.Default.usesStandardMagicGallerySet)
    }

    func test_hapticIntensity_roundTripsThroughRealDefaults() {
        let preferences = AppPreferences(store: defaults)

        for intensity: HapticIntensity in [.light, .medium, .heavy] {
            preferences.hapticIntensity = intensity
            XCTAssertEqual(preferences.hapticIntensity, intensity)
        }
    }
}

