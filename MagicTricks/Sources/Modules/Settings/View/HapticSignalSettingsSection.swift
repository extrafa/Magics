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
            intensitySection
            speedSection
            groupingSection
        }
    }

    private var intensitySection: some View {
        SettingsSection(title: String(localized: "settings.haptics.strength")) {
            HStack(spacing: 0) {
                ForEach(HapticIntensity.allCases, id: \.self) { intensity in
                    Button {
                        settings.hapticIntensity = intensity
                    } label: {
                        Text(intensity.localizedTitle)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .foregroundStyle(settings.hapticIntensity == intensity ? Color.secondaryText : Color.primaryText.opacity(0.55))
                            .background(settings.hapticIntensity == intensity ? Color.button : Color.clear)
                            .animation(.easeInOut(duration: 0.18), value: settings.hapticIntensity)
                    }
                    .buttonStyle(.plain)

                    if intensity != HapticIntensity.allCases.last {
                        Rectangle()
                            .fill(Color.primaryText.opacity(0.12))
                            .frame(width: 1, height: 22)
                    }
                }
            }
            .background(Color.grayCard)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.primaryText.opacity(0.1), lineWidth: 1)
            }
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
