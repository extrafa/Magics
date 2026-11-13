//
//  MotionSettingsSection.swift
//  Magic Tricks
//
//  Created by Ross on 01/06/2026.
//

import SwiftUI

private let hapticsKey = L10nDomain("settings.haptics")

// What the Face Down test is doing, for the row it sits on.
enum FaceDownTestState: Equatable {
    case idle
    case waiting
    case detected
}

struct MotionSettingsSection: View {

    @ObservedObject var settings: SettingsStore
    var faceDownTest: FaceDownTestState = .idle
    // How long the test waits, for the countdown ring.
    var faceDownTestTimeout: TimeInterval = 10
    var onFaceDownInfo: Completion?
    var onFaceDownTest: Completion?

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

    private var faceDownStatus: String? {
        switch faceDownTest {
        case .idle: nil
        case .waiting: String(localized: hapticsKey("faceDownTest.waiting"))
        case .detected: String(localized: hapticsKey("faceDownTest.detected"))
        }
    }

    var body: some View {
        SettingsSection(title: String(localized: "settings.trigger")) {
            VStack(spacing: 0) {
                SettingsToggleRow(
                    title: String(localized: "settings.faceDown"),
                    subtitle: String(localized: hapticsKey("faceDownDescription")),
                    isOn: $settings.isSecretGestureEnabled.animation(),
                    status: faceDownStatus
                ) {
                    SettingsRoundButton(style: .info, label: String(localized: hapticsKey("infoButton"))) {
                        onFaceDownInfo?()
                    }
                    SettingsRoundButton(
                        style: .test,
                        isActive: faceDownTest == .waiting,
                        isDone: faceDownTest == .detected,
                        countdown: faceDownTestTimeout,
                        label: String(localized: hapticsKey("testButton"))
                    ) {
                        onFaceDownTest?()
                    }
                }

                if settings.isSecretGestureEnabled {
                    cardDivider

                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: hapticsKey("holdDurationDescription")))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.textSecondary)
                            // The stepper below is labelled with this same sentence.
                            .accessibilityHidden(true)

                        SettingsStepper(
                            value: $settings.screenDownHoldDuration,
                            label: String(localized: hapticsKey("holdDurationDescription")),
                            range: AppPreferences.Range.screenDownHoldDuration,
                            step: 0.10,
                            format: "%.2fs"
                        )
                    }
                    .padding(18)
                }
            }
            .cardSurface(cornerRadius: 20)
        }
    }
}
