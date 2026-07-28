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
        store.bools[AppPreferences.Key.secretGestureEnabled] = true
        store.doubles[AppPreferences.Key.screenDownHoldDuration] = 0.75

        let settings = SettingsStore(preferences: AppPreferences(store: store))

        XCTAssertEqual(settings.hapticSpeedMultiplier, 1.35)
        XCTAssertTrue(settings.isHapticGroupByThreeEnabled)
        XCTAssertTrue(settings.isSecretGestureEnabled)
        XCTAssertEqual(settings.screenDownHoldDuration, 0.75)
    }

    func test_assigningValues_writesThroughPreferencesLayer() {
        let store = MockSettingsPreferenceStore()
        let settings = SettingsStore(preferences: AppPreferences(store: store))

        settings.hapticSpeedMultiplier = 1.5
        settings.isHapticGroupByThreeEnabled = true
        settings.isSecretGestureEnabled = true
        settings.screenDownHoldDuration = 0.9

        XCTAssertEqual(store.doubles[AppPreferences.Key.hapticSpeedMultiplier], 1.5)
        XCTAssertEqual(store.bools[AppPreferences.Key.hapticGroupByThreeEnabled], true)
        XCTAssertEqual(store.bools[AppPreferences.Key.secretGestureEnabled], true)
        XCTAssertEqual(store.doubles[AppPreferences.Key.screenDownHoldDuration], 0.9)
    }

    func test_resetMethods_restoreStateFromPreferencesDefaults() {
        let store = MockSettingsPreferenceStore()
        let settings = SettingsStore(preferences: AppPreferences(store: store))

        settings.hapticSpeedMultiplier = 1.5
        settings.isHapticGroupByThreeEnabled = true
        settings.isSecretGestureEnabled = true
        settings.screenDownHoldDuration = 0.9

        settings.resetHapticSettings()
        settings.resetMotionSettings()

        XCTAssertEqual(settings.hapticSpeedMultiplier, AppPreferences.Default.hapticSpeedMultiplier)
        XCTAssertEqual(settings.isHapticGroupByThreeEnabled, AppPreferences.Default.hapticGroupByThreeEnabled)
        XCTAssertEqual(settings.isSecretGestureEnabled, AppPreferences.Default.secretGestureEnabled)
        XCTAssertEqual(settings.screenDownHoldDuration, AppPreferences.Default.screenDownHoldDuration)
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

    func object(forKey defaultName: String) -> Any? {
        bools[defaultName] ?? doubles[defaultName]
    }

    func bool(forKey defaultName: String) -> Bool {
        bools[defaultName] ?? false
    }

    func double(forKey defaultName: String) -> Double {
        doubles[defaultName] ?? 0
    }

    func set(_ value: Bool, forKey defaultName: String) {
        bools[defaultName] = value
    }

    func set(_ value: Double, forKey defaultName: String) {
        doubles[defaultName] = value
    }
}
