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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .subheadline) private var segmentHeight: CGFloat = 48

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            intensitySection
            speedSection
            groupingSection
        }
    }

    private var intensitySection: some View {
        SettingsSection(title: String(localized: key("strength"))) {
            if dynamicTypeSize.isAccessibilitySize {
                stackedIntensityPicker
            } else {
                slidingIntensityPicker
            }
        }
    }

    private var slidingIntensityPicker: some View {
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
                        intensityButton(intensity) { isSelected in
                            segmentTitle(intensity, isSelected: isSelected)
                                .frame(height: proxy.size.height)
                        }
                    }
                }
            }
            .animation(.easeInOut(duration: 0.18), value: settings.hapticIntensity)
        }
        .frame(height: segmentHeight)
        .modifier(SegmentedContainer())
    }

    // The sliding highlight needs three words side by side; at accessibility sizes they stack instead.
    private var stackedIntensityPicker: some View {
        VStack(spacing: 0) {
            ForEach(HapticIntensity.allCases, id: \.self) { intensity in
                intensityButton(intensity) { isSelected in
                    segmentTitle(intensity, isSelected: isSelected)
                        .padding(.vertical, 14)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .fill(Color.buttonPrimary)
                            }
                        }
                }
            }
        }
        .padding(selectionInset)
        .animation(.easeInOut(duration: 0.18), value: settings.hapticIntensity)
        .modifier(SegmentedContainer())
    }

    private func intensityButton<Label: View>(
        _ intensity: HapticIntensity,
        @ViewBuilder label: (Bool) -> Label
    ) -> some View {
        let isSelected = settings.hapticIntensity == intensity
        return Button {
            settings.hapticIntensity = intensity
        } label: {
            label(isSelected)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func segmentTitle(_ intensity: HapticIntensity, isSelected: Bool) -> some View {
        Text(intensity.localizedTitle)
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .frame(maxWidth: .infinity)
            .foregroundStyle(isSelected ? Color.backgroundScreen : Color.textPrimary)
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

private struct SegmentedContainer: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.textPrimary.opacity(0.1), lineWidth: 1)
            }
    }
}
