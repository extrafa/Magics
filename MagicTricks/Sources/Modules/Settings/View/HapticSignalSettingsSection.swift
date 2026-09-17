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
                            .foregroundStyle(settings.hapticIntensity == intensity ? Color.textSecondary : Color.textPrimary.opacity(0.55))
                            .background(settings.hapticIntensity == intensity ? Color.buttonPrimary : Color.clear)
                            .animation(.easeInOut(duration: 0.18), value: settings.hapticIntensity)
                    }
                    .buttonStyle(.plain)

                    if intensity != HapticIntensity.allCases.last {
                        Rectangle()
                            .fill(Color.textPrimary.opacity(0.12))
                            .frame(width: 1, height: 22)
                    }
                }
            }
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.textPrimary.opacity(0.1), lineWidth: 1)
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
            .cardSurface(cornerRadius: 20)
        }
    }

    private var groupingSection: some View {
        SettingsSection(title: String(localized: "settings.haptics.grouping")) {
            SettingsToggleRow(
                title: String(localized: "settings.haptics.groupVibrations"),
                subtitle: String(localized: "settings.haptics.groupingDescription"),
                isOn: $settings.isHapticGroupByThreeEnabled
            )
            .cardSurface(cornerRadius: 20)
        }
    }
}
