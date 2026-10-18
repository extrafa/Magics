//
//  HapticSignalSettingsSection.swift
//  Magic Tricks
//
//  Created by Ross on 02/06/2026.
//

import SwiftUI

private let key = L10nDomain("settings.haptics")
private let selectionInset: CGFloat = 3

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
        SettingsSection(title: String(localized: key("strength"))) {
            GeometryReader { proxy in
                let segmentWidth = proxy.size.width / CGFloat(HapticIntensity.allCases.count)
                let selectedIndex = HapticIntensity.allCases.firstIndex(of: settings.hapticIntensity) ?? 0

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(Color.buttonPrimary)
                        .frame(width: segmentWidth - selectionInset * 2, height: proxy.size.height - selectionInset * 2)
                        .offset(x: segmentWidth * CGFloat(selectedIndex) + selectionInset)

                    HStack(spacing: 0) {
                        ForEach(HapticIntensity.allCases, id: \.self) { intensity in
                            let isSelected = settings.hapticIntensity == intensity
                            Button {
                                settings.hapticIntensity = intensity
                            } label: {
                                Text(intensity.localizedTitle)
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: proxy.size.height)
                                    .foregroundStyle(isSelected ? Color.backgroundScreen : Color.textPrimary)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(isSelected ? .isSelected : [])
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.18), value: settings.hapticIntensity)
            }
            .frame(height: 48)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.textPrimary.opacity(0.1), lineWidth: 1)
            }
        }
    }

    private var speedSection: some View {
        SettingsSection(title: String(localized: key("speed"))) {
            SettingsStepper(
                value: $settings.hapticSpeedMultiplier,
                label: String(localized: key("speed")),
                range: AppPreferences.Range.hapticSpeedMultiplier,
                step: 0.5,
                format: "%.1fx"
            )
            .padding(18)
            .cardSurface(cornerRadius: 20)
        }
    }

    private var groupingSection: some View {
        SettingsSection(title: String(localized: key("grouping"))) {
            SettingsToggleRow(
                title: String(localized: key("groupVibrations")),
                subtitle: String(localized: key("groupingDescription")),
                isOn: $settings.isHapticGroupByThreeEnabled
            )
            .cardSurface(cornerRadius: 20)
        }
    }
}
