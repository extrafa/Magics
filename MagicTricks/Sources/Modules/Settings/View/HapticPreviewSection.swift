//
//  HapticPreviewSection.swift
//  Magic Tricks
//
//  Created by Ross on 02/06/2026.
//

import SwiftUI

struct HapticPreviewSection: View {
    let testNumber: Int
    let isTesting: Bool
    let isWaitingForGesture: Bool
    let action: () -> Void

    private var buttonLabel: String {
        isWaitingForGesture
            ? String(localized: "settings.faceDown")
            : String(localized: "settings.haptics.tryVibration")
    }

    private var buttonIcon: String {
        isWaitingForGesture ? "iphone.and.arrow.forward" : "dot.radiowaves.left.and.right"
    }

    var body: some View {
        SettingsSection(title: String(localized: "settings.preview")) {
            VStack(alignment: .leading, spacing: 14) {
                Text(String.localizedStringWithFormat(String(localized: "settings.haptics.testNumber"), testNumber))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.primaryText)

                Button(action: action) {
                    Label(buttonLabel, systemImage: buttonIcon)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(PrimaryTrickButtonStyle(color: .button))
                .disabled(isTesting)
                .animation(.easeInOut(duration: 0.2), value: isWaitingForGesture)
            }
            .padding(18)
            .settingsCard()
        }
    }
}
