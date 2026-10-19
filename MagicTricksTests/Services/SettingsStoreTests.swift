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
        let store = MockPreferenceStore()
        store.storage[AppPreferences.Key.hapticSpeedMultiplier] = 1.35
        store.storage[AppPreferences.Key.hapticGroupByThreeEnabled] = true
        store.storage[AppPreferences.Key.hapticIntensity] = HapticIntensity.light.storageValue
        store.storage[AppPreferences.Key.secretGestureEnabled] = true
        store.storage[AppPreferences.Key.screenDownHoldDuration] = 0.75
        store.storage[AppPreferences.Key.isExitHintEnabled] = false

        let settings = SettingsStore(preferences: AppPreferences(store: store))

        XCTAssertEqual(settings.hapticSpeedMultiplier, 1.35)
        XCTAssertTrue(settings.isHapticGroupByThreeEnabled)
        XCTAssertEqual(settings.hapticIntensity, .light)
        XCTAssertTrue(settings.isSecretGestureEnabled)
        XCTAssertEqual(settings.screenDownHoldDuration, 0.75)
        XCTAssertFalse(settings.isExitHintEnabled)
    }

    func test_assigningValues_writesThroughPreferencesLayer() {
        let store = MockPreferenceStore()
        let settings = SettingsStore(preferences: AppPreferences(store: store))

        settings.hapticSpeedMultiplier = 1.5
        settings.isHapticGroupByThreeEnabled = true
        settings.hapticIntensity = .light
        settings.isSecretGestureEnabled = true
        settings.screenDownHoldDuration = 0.9
        settings.isExitHintEnabled = false

        XCTAssertEqual(store.storage[AppPreferences.Key.hapticSpeedMultiplier] as? Double, 1.5)
        XCTAssertEqual(store.storage[AppPreferences.Key.hapticGroupByThreeEnabled] as? Bool, true)
        XCTAssertEqual(store.storage[AppPreferences.Key.hapticIntensity] as? Double, HapticIntensity.light.storageValue)
        XCTAssertEqual(store.storage[AppPreferences.Key.secretGestureEnabled] as? Bool, true)
        XCTAssertEqual(store.storage[AppPreferences.Key.screenDownHoldDuration] as? Double, 0.9)
        XCTAssertEqual(store.storage[AppPreferences.Key.isExitHintEnabled] as? Bool, false)
    }

    func test_resetMethods_restoreStateFromPreferencesDefaults() {
        let store = MockPreferenceStore()
        let settings = SettingsStore(preferences: AppPreferences(store: store))

        settings.hapticSpeedMultiplier = 2.2
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
        let settings = SettingsStore(preferences: AppPreferences(store: MockPreferenceStore()))

        XCTAssertNil(settings.appShareURL)
        XCTAssertFalse(settings.appShareText.isEmpty)
    }
}
