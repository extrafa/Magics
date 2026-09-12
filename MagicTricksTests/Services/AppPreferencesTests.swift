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
        XCTAssertEqual(preferences.magicGalleryGestureMode, .tap)
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
}

private final class MockPreferenceStore: PreferenceStoring {
    var storage: [String: Any] = [:]

    func object(forKey defaultName: String) -> Any? { storage[defaultName] }
    func bool(forKey defaultName: String) -> Bool { (storage[defaultName] as? Bool) ?? false }
    func double(forKey defaultName: String) -> Double { (storage[defaultName] as? Double) ?? 0 }
    func stringArray(forKey defaultName: String) -> [String]? { storage[defaultName] as? [String] }
    func set(_ value: Any?, forKey defaultName: String) { storage[defaultName] = value }
}
