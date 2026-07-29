//
//  MotionSettingsSection.swift
//  Magic Tricks
//
//  Created by Ross on 01/06/2026.
//

import SwiftUI

struct MotionSettingsSection: View {

    enum Copy {
        case motion
        case haptics

        var triggerTitle: String {
            switch self {
            case .motion: String(localized: "settings.motion.gestureTrigger")
            case .haptics: String(localized: "settings.trigger")
            }
        }

        var gestureTitle: String {
            switch self {
            case .motion: String(localized: "settings.motion.secretGesture")
            case .haptics: String(localized: "settings.faceDown")
            }
        }

        var gestureDescription: String {
            switch self {
            case .motion: String(localized: "settings.motion.secretGestureDescription")
            case .haptics: String(localized: "settings.haptics.faceDownDescription")
            }
        }

        var holdDescription: String? {
            switch self {
            case .motion: nil
            case .haptics: String(localized: "settings.haptics.holdDurationDescription")
            }
        }
    }

    @ObservedObject var settings: SettingsStore
    let copy: Copy
    var resetAction: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            secretGestureSection
            holdDurationSection

            if let resetAction {
                SettingsResetButton(action: resetAction)
            }
        }
    }

    private var secretGestureSection: some View {
        SettingsSection(title: copy.triggerTitle) {
            Toggle(isOn: $settings.isSecretGestureEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(copy.gestureTitle)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.primaryText)

                    Text(copy.gestureDescription)
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
                if let holdDescription = copy.holdDescription {
                    Text(holdDescription)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.primaryText.opacity(0.58))
                }

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
