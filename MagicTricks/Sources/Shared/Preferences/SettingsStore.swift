//
//  SettingsStore.swift
//  Magic Tricks
//
//  Created by Ross on 29/05/2026.
//

import Foundation

final class SettingsStore: ObservableObject {

    var hapticSpeedMultiplier: Double {
        get { preferences.hapticSpeedMultiplier }
        set {
            objectWillChange.send()
            preferences.hapticSpeedMultiplier = newValue
        }
    }

    var isHapticGroupByThreeEnabled: Bool {
        get { preferences.isHapticGroupByThreeEnabled }
        set {
            objectWillChange.send()
            preferences.isHapticGroupByThreeEnabled = newValue
        }
    }

    var hapticIntensity: HapticIntensity {
        get { preferences.hapticIntensity }
        set {
            objectWillChange.send()
            preferences.hapticIntensity = newValue
        }
    }

    var isSecretGestureEnabled: Bool {
        get { preferences.isSecretGestureEnabled }
        set {
            objectWillChange.send()
            preferences.isSecretGestureEnabled = newValue
        }
    }

    var screenDownHoldDuration: TimeInterval {
        get { preferences.screenDownHoldDuration }
        set {
            objectWillChange.send()
            preferences.screenDownHoldDuration = newValue
        }
    }

    var isExitHintEnabled: Bool {
        get { preferences.isExitHintEnabled }
        set {
            objectWillChange.send()
            preferences.isExitHintEnabled = newValue
        }
    }

    private let preferences: AppPreferences
    private let appStoreURL: URL?

    var appShareURL: URL? {
        appStoreURL
    }

    var appShareText: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "Magic Tricks"
    }

    init(preferences: AppPreferences = .shared, appStoreURL: URL? = AppConfig.appStoreURL) {
        self.preferences = preferences
        self.appStoreURL = appStoreURL
    }

    func resetHapticSettings() {
        objectWillChange.send()
        preferences.resetHapticSettings()
    }

    func resetMotionSettings() {
        objectWillChange.send()
        preferences.resetMotionSettings()
    }
}
