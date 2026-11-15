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


final class HapticsUnavailableNoticeTests: XCTestCase {

    func test_shouldShow_onADeviceThatCanVibrate_isFalse() {
        XCTAssertFalse(HapticsUnavailableNotice.shouldShow(isUnavailable: false, isInternalBuild: true, isHiddenByTester: false))
    }

    func test_shouldShow_whenUnavailable_isTrue() {
        XCTAssertTrue(HapticsUnavailableNotice.shouldShow(isUnavailable: true, isInternalBuild: true, isHiddenByTester: false))
        XCTAssertTrue(HapticsUnavailableNotice.shouldShow(isUnavailable: true, isInternalBuild: false, isHiddenByTester: false))
    }

    func test_shouldShow_testerHidesItInAnInternalBuild() {
        XCTAssertFalse(HapticsUnavailableNotice.shouldShow(isUnavailable: true, isInternalBuild: true, isHiddenByTester: true))
    }

    func test_shouldShow_testerFlagDoesNothingInAReleaseBuild() {
        XCTAssertTrue(HapticsUnavailableNotice.shouldShow(isUnavailable: true, isInternalBuild: false, isHiddenByTester: true))
    }
}

final class SettingsStepperDisplayTests: XCTestCase {

    func test_speedDefault_isShownAsOne_withTwoEvenStepsDownAndTwoUp() {
        let scale = AppPreferences.Default.hapticSpeedMultiplier
        let step = 0.25 * scale
        let range = AppPreferences.Range.hapticSpeedMultiplier
        let stops = (-2...2).map { scale + Double($0) * step }
        let shown = stops.map { SettingsStepper.displayText(for: $0, format: "%.2fx", displayScale: scale) }

        XCTAssertEqual(shown, ["0.50x", "0.75x", "1.00x", "1.25x", "1.50x"])
        XCTAssertEqual(stops.first, range.lowerBound)
        XCTAssertEqual(stops.last, range.upperBound)
    }

    func test_speedSteps_landOnTheSameFiveStopsInBothDirections() {
        let range = AppPreferences.Range.hapticSpeedMultiplier
        let step = 0.25 * AppPreferences.Default.hapticSpeedMultiplier

        var up = [range.lowerBound]
        for _ in 0..<5 { up.append(SettingsStepper.stepped(up.last!, by: step, in: range)) }
        var down = [range.upperBound]
        for _ in 0..<5 { down.append(SettingsStepper.stepped(down.last!, by: -step, in: range)) }

        XCTAssertEqual(up, [0.75, 1.125, 1.5, 1.875, 2.25, 2.25])
        XCTAssertEqual(down, [2.25, 1.875, 1.5, 1.125, 0.75, 0.75])
    }

    func test_withoutAScale_theValueIsShownAsStored() {
        XCTAssertEqual(SettingsStepper.displayText(for: 0.3, format: "%.2fs", displayScale: 1), "0.30s")
    }
}

final class InfoSheetTextsTests: XCTestCase {

    private let keys = [
        "settings.info.grouping.title", "settings.info.grouping.message", "settings.info.grouping.hint",
        "settings.info.faceDown.title", "settings.info.faceDown.message", "settings.info.faceDown.hint",
        "settings.info.faceDownMissed.title", "settings.info.faceDownMissed.message", "settings.info.faceDownMissed.hint"
    ]

    private func bundle(_ language: String) throws -> Bundle {
        let path = try XCTUnwrap(Bundle(for: SettingsStore.self).path(forResource: language, ofType: "lproj"))
        return try XCTUnwrap(Bundle(path: path))
    }

    func test_everyInfoSheetText_existsInBothLanguages_andTheSpanishIsNotTheEnglish() throws {
        let english = try bundle("en")
        let spanish = try bundle("es")

        for key in keys {
            let en = english.localizedString(forKey: key, value: "MISSING", table: nil)
            let es = spanish.localizedString(forKey: key, value: "MISSING", table: nil)

            XCTAssertNotEqual(en, "MISSING", "\(key) has no English text")
            XCTAssertNotEqual(es, "MISSING", "\(key) has no Spanish text")
            XCTAssertNotEqual(en, es, "\(key) is not translated")
        }
    }

    func test_theHints_nameTheRealButtonsAndTheSettingTheyPointTo() throws {
        for language in ["en", "es"] {
            let bundle = try bundle(language)
            func text(_ key: String) -> String { bundle.localizedString(forKey: key, value: "MISSING", table: nil) }
            let gotIt = text("common.gotIt")
            let tryVibration = text("settings.haptics.tryVibration")
            let faceDown = text("settings.faceDown")

            let faceDownHint = text("settings.info.faceDown.hint")
            for name in [gotIt, tryVibration, faceDown] {
                XCTAssertTrue(faceDownHint.contains(name), "\(language): the Face Down hint does not name \"\(name)\"")
            }
            let missedHint = text("settings.info.faceDownMissed.hint")
            for name in [gotIt, tryVibration] {
                XCTAssertTrue(missedHint.contains(name), "\(language): the not-detected hint does not name \"\(name)\"")
            }
        }
    }

    func test_theNotDetectedText_keepsTheNumberOfSecondsItWaited() throws {
        for language in ["en", "es"] {
            let text = try bundle(language).localizedString(forKey: "settings.info.faceDownMissed.message", value: nil, table: nil)

            XCTAssertTrue(text.contains("%lld"), "the \(language) text lost the seconds")
        }
    }
}

