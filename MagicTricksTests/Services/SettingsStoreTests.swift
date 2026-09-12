//
//  SettingsStoreTests.swift
//  MagicTricksTests
//
//  Created by Ross on 29/05/2026.
//

import XCTest
@testable import MagicTricks

@MainActor
final class SettingsStoreTests: XCTestCase {

    func test_init_readsCurrentPreferenceValues() {
        let store = MockSettingsPreferenceStore()
        store.doubles[AppPreferences.Key.hapticSpeedMultiplier] = 1.35
        store.bools[AppPreferences.Key.hapticGroupByThreeEnabled] = true
        store.doubles[AppPreferences.Key.hapticIntensity] = HapticIntensity.light.storageValue
        store.bools[AppPreferences.Key.secretGestureEnabled] = true
        store.doubles[AppPreferences.Key.screenDownHoldDuration] = 0.75
        store.bools[AppPreferences.Key.isExitHintEnabled] = false

        let settings = SettingsStore(preferences: AppPreferences(store: store))

        XCTAssertEqual(settings.hapticSpeedMultiplier, 1.35)
        XCTAssertTrue(settings.isHapticGroupByThreeEnabled)
        XCTAssertEqual(settings.hapticIntensity, .light)
        XCTAssertTrue(settings.isSecretGestureEnabled)
        XCTAssertEqual(settings.screenDownHoldDuration, 0.75)
        XCTAssertFalse(settings.isExitHintEnabled)
    }

    func test_assigningValues_writesThroughPreferencesLayer() {
        let store = MockSettingsPreferenceStore()
        let settings = SettingsStore(preferences: AppPreferences(store: store))

        settings.hapticSpeedMultiplier = 1.5
        settings.isHapticGroupByThreeEnabled = true
        settings.hapticIntensity = .light
        settings.isSecretGestureEnabled = true
        settings.screenDownHoldDuration = 0.9
        settings.isExitHintEnabled = false

        XCTAssertEqual(store.doubles[AppPreferences.Key.hapticSpeedMultiplier], 1.5)
        XCTAssertEqual(store.bools[AppPreferences.Key.hapticGroupByThreeEnabled], true)
        XCTAssertEqual(store.doubles[AppPreferences.Key.hapticIntensity], HapticIntensity.light.storageValue)
        XCTAssertEqual(store.bools[AppPreferences.Key.secretGestureEnabled], true)
        XCTAssertEqual(store.doubles[AppPreferences.Key.screenDownHoldDuration], 0.9)
        XCTAssertEqual(store.bools[AppPreferences.Key.isExitHintEnabled], false)
    }

    func test_resetMethods_restoreStateFromPreferencesDefaults() {
        let store = MockSettingsPreferenceStore()
        let settings = SettingsStore(preferences: AppPreferences(store: store))

        settings.hapticSpeedMultiplier = 1.5
        settings.isHapticGroupByThreeEnabled = true
        settings.hapticIntensity = .light
        settings.isSecretGestureEnabled = true
        settings.screenDownHoldDuration = 0.9
        settings.isExitHintEnabled = false

        settings.resetHapticSettings()
        settings.resetMotionSettings()

        XCTAssertEqual(settings.hapticSpeedMultiplier, AppPreferences.Default.hapticSpeedMultiplier)
        XCTAssertEqual(settings.isHapticGroupByThreeEnabled, AppPreferences.Default.hapticGroupByThreeEnabled)
        XCTAssertEqual(settings.hapticIntensity, AppPreferences.Default.hapticIntensity)
        XCTAssertEqual(settings.isSecretGestureEnabled, AppPreferences.Default.secretGestureEnabled)
        XCTAssertEqual(settings.screenDownHoldDuration, AppPreferences.Default.screenDownHoldDuration)
        XCTAssertEqual(settings.isExitHintEnabled, AppPreferences.Default.isExitHintEnabled)
    }

    func test_appShareFallbackText_usesDisplayNameWhenURLIsNotConfigured() {
        let settings = SettingsStore(preferences: AppPreferences(store: MockSettingsPreferenceStore()))

        XCTAssertNil(settings.appShareURL)
        XCTAssertFalse(settings.appShareText.isEmpty)
    }
}

private final class MockSettingsPreferenceStore: PreferenceStoring {
    var bools: [String: Bool] = [:]
    var doubles: [String: Double] = [:]
    var stringArrays: [String: [String]] = [:]

    func object(forKey defaultName: String) -> Any? {
        bools[defaultName] ?? doubles[defaultName] ?? stringArrays[defaultName]
    }

    func bool(forKey defaultName: String) -> Bool {
        bools[defaultName] ?? false
    }

    func double(forKey defaultName: String) -> Double {
        doubles[defaultName] ?? 0
    }

    func stringArray(forKey defaultName: String) -> [String]? {
        stringArrays[defaultName]
    }

    func set(_ value: Any?, forKey defaultName: String) {
        switch value {
        case let value as Bool:     bools[defaultName] = value
        case let value as Double:   doubles[defaultName] = value
        case let value as [String]: stringArrays[defaultName] = value
        default: break
        }
    }
}
