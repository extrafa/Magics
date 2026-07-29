//
//  HapticSettingsScreen.swift
//  Magic Tricks
//
//  Created by Ross on 24/04/2026.
//

import SwiftUI

struct HapticSettingsScreen: View {
    @EnvironmentObject private var settings: SettingsStore
    @State private var isTesting = false
    @State private var isWaitingForGesture = false

    private let haptics: CountHapticPlaying
    private let gestureManager: PhoneTiltGestureManager
    private let testNumber = 7

    init(haptics: CountHapticPlaying? = nil) {
        self.haptics = haptics ?? HapticManager.shared
        self.gestureManager = PhoneTiltGestureManager()
    }

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    HapticSignalSettingsSection(settings: settings)
                    HapticPreviewSection(
                        testNumber: testNumber,
                        isTesting: isTesting,
                        isWaitingForGesture: isWaitingForGesture,
                        action: playPreview
                    )
                    MotionSettingsSection(settings: settings, copy: .haptics)
                    resetButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 36)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(String(localized: "settings.haptics.title"))
        .navigationBarTitleDisplayMode(.inline)
        .fontDesign(.rounded)
    }

    private var resetButton: some View {
        SettingsResetButton(action: resetDefaults)
    }

    private func playPreview() {
        guard !isTesting else { return }
        isTesting = true

        if settings.isSecretGestureEnabled {
            isWaitingForGesture = true
            Task { @MainActor in
                let triggered = await gestureManager.waitForScreenDownGesture()
                isWaitingForGesture = false
                guard triggered else {
                    isTesting = false
                    return
                }
                haptics.playTrainingDigit(testNumber) {
                    isTesting = false
                }
            }
        } else {
            haptics.playTrainingDigit(testNumber) {
                isTesting = false
            }
        }
    }

    private func resetDefaults() {
        settings.resetHapticSettings()
        settings.resetMotionSettings()
    }
}

#Preview {
    NavigationStack {
        HapticSettingsScreen()
            .environmentObject(SettingsStore())
    }
}
