//
//  MotionSettingsSection.swift
//  Magic Tricks
//
//  Created by Ross on 01/06/2026.
//

import SwiftUI

struct MotionSettingsSection: View {

    @ObservedObject var settings: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            secretGestureSection
            holdDurationSection
        }
    }

    private var secretGestureSection: some View {
        SettingsSection(title: String(localized: "settings.trigger")) {
            Toggle(isOn: $settings.isSecretGestureEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "settings.faceDown"))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.primaryText)

                    Text(String(localized: "settings.haptics.faceDownDescription"))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.primaryText.opacity(0.58))
                }
            }
            .tint(TrickPalette.Collection.timeControl)
            .padding(18)
            .settingsCard()
        }
    }

    private var holdDurationSection: some View {
        SettingsSection(title: String(localized: "settings.holdDuration")) {
            VStack(alignment: .leading, spacing: 16) {
                Text(String(localized: "settings.haptics.holdDurationDescription"))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.primaryText.opacity(0.58))

                SettingsStepper(
                    value: $settings.screenDownHoldDuration,
                    range: AppPreferences.Range.screenDownHoldDuration,
                    step: 0.10,
                    format: "%.2fs"
                )
                .disabled(!settings.isSecretGestureEnabled)
            }
            .opacity(settings.isSecretGestureEnabled ? 1 : 0.42)
            .padding(18)
            .settingsCard()
        }
    }
}
