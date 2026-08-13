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
                    HStack(spacing: 10) {
                        Label(
                            isWaitingForGesture
                                ? String(localized: "settings.faceDown")
                                : String(localized: "settings.haptics.tryVibration"),
                            systemImage: buttonIcon
                        )

                        if isWaitingForGesture {
                            WaitingDotsView()
                        }
                    }
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

private struct WaitingDotsView: View {
    @State private var phase = 0

    private let timer = Timer.publish(every: 0.38, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .frame(width: 5, height: 5)
                    .opacity(phase == i ? 1.0 : 0.3)
                    .scaleEffect(phase == i ? 1.3 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: phase)
            }
        }
        .onReceive(timer) { _ in
            phase = (phase + 1) % 3
        }
    }
}
