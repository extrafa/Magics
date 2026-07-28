//
//  SettingsStore.swift
//  Magic Tricks
//
//  Created by Ross on 29/05/2026.
//

import Foundation

final class SettingsStore: ObservableObject {

    @Published var hapticSpeedMultiplier: Double {
        didSet { preferences.hapticSpeedMultiplier = hapticSpeedMultiplier }
    }

    @Published var isHapticGroupByThreeEnabled: Bool {
        didSet { preferences.isHapticGroupByThreeEnabled = isHapticGroupByThreeEnabled }
    }

    @Published var isSecretGestureEnabled: Bool {
        didSet { preferences.isSecretGestureEnabled = isSecretGestureEnabled }
    }

    @Published var screenDownHoldDuration: TimeInterval {
        didSet { preferences.screenDownHoldDuration = screenDownHoldDuration }
    }

    private let preferences: AppPreferences

    var appShareURL: URL? {
        AppConfig.appStoreURL
    }

    var appShareText: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "Magic Tricks"
    }

    init(preferences: AppPreferences = .shared) {
        self.preferences = preferences
        self.hapticSpeedMultiplier = preferences.hapticSpeedMultiplier
        self.isHapticGroupByThreeEnabled = preferences.isHapticGroupByThreeEnabled
        self.isSecretGestureEnabled = preferences.isSecretGestureEnabled
        self.screenDownHoldDuration = preferences.screenDownHoldDuration
    }

    func resetHapticSettings() {
        preferences.resetHapticSettings()
        hapticSpeedMultiplier = AppPreferences.Default.hapticSpeedMultiplier
        isHapticGroupByThreeEnabled = AppPreferences.Default.hapticGroupByThreeEnabled
    }

    func resetMotionSettings() {
        preferences.resetMotionSettings()
        isSecretGestureEnabled = AppPreferences.Default.secretGestureEnabled
        screenDownHoldDuration = AppPreferences.Default.screenDownHoldDuration
    }
}
