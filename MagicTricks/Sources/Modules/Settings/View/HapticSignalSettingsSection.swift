//
//  HapticSignalSettingsSection.swift
//  Magic Tricks
//
//  Created by Ross on 02/06/2026.
//

import SwiftUI

struct HapticSignalSettingsSection: View {
    @ObservedObject var settings: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            speedSection
            groupingSection
        }
    }

    private var speedSection: some View {
        SettingsSection(title: String(localized: "settings.haptics.speed")) {
            SettingsStepper(
                value: $settings.hapticSpeedMultiplier,
                range: AppPreferences.Range.hapticSpeedMultiplier,
                step: 0.5,
                format: "%.1fx"
            )
            .padding(18)
            .settingsCard()
        }
    }

    private var groupingSection: some View {
        SettingsSection(title: String(localized: "settings.haptics.grouping")) {
            Toggle(isOn: $settings.isHapticGroupByThreeEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "settings.haptics.groupVibrations"))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.primaryText)

                    Text(String(localized: "settings.haptics.groupingDescription"))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.primaryText.opacity(0.58))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(TrickPalette.Collection.timeControl)
            .padding(18)
            .settingsCard()
        }
    }
}
