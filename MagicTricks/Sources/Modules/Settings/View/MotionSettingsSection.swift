//
//  MotionSettingsSection.swift
//  Magic Tricks
//
//  Created by Ross on 01/06/2026.
//

import SwiftUI

struct MotionSettingsSection: View {

    @ObservedObject var settings: SettingsStore

    private var cardDivider: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, Color.primary.opacity(0.12), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
            .padding(.horizontal, 18)
    }

    var body: some View {
        SettingsSection(title: String(localized: "settings.trigger")) {
            VStack(spacing: 0) {
                Toggle(isOn: $settings.isSecretGestureEnabled.animation()) {
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

                if settings.isSecretGestureEnabled {
                    cardDivider

                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "settings.haptics.holdDurationDescription"))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.primaryText.opacity(0.58))

                        SettingsStepper(
                            value: $settings.screenDownHoldDuration,
                            range: AppPreferences.Range.screenDownHoldDuration,
                            step: 0.10,
                            format: "%.2fs"
                        )
                    }
                    .padding(18)
                }
            }
            .settingsCard()
        }
    }
}
