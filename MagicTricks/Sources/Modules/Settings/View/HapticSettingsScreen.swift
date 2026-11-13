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
    @State private var gestureTask: Task<Void, Never>?
    @State private var faceDownTest = FaceDownTestState.idle
    @State private var faceDownTestTask: Task<Void, Never>?
    @State private var infoTopic: SettingsInfoTopic?
    // State, not a let: a re-created screen would otherwise stop a different manager than the one waiting.
    @State private var gestureManager = PhoneTiltGestureManager()

    private let haptics: CountHapticPlaying
    private let testNumber = 7
    // How long a Face Down test waits before it gives up and says how to do it.
    private static let faceDownTimeout: TimeInterval = 10
    // A short sample, so choosing Weak, Medium or Strong shows what it feels like without the full preview.
    private let strengthSampleCount = 3

    init(haptics: CountHapticPlaying? = nil) {
        self.haptics = haptics ?? HapticManager.shared
    }

    var body: some View {
        ZStack {
            Color.backgroundScreen.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    HapticsUnavailableNotice()
                    HapticSignalSettingsSection(
                        settings: settings,
                        onIntensityChosen: playStrengthSample,
                        onGroupingInfo: { infoTopic = .grouping },
                        onGroupingTest: playGroupingSample
                    )
                    MotionSettingsSection(
                        settings: settings,
                        faceDownTest: faceDownTest,
                        faceDownTestTimeout: Self.faceDownTimeout,
                        onFaceDownInfo: { infoTopic = .faceDown },
                        onFaceDownTest: startFaceDownTest
                    )
                    HapticPreviewSection(
                        testNumber: testNumber,
                        isTesting: isTesting,
                        isWaitingForGesture: isWaitingForGesture,
                        action: playPreview
                    )
                    SettingsResetButton(action: resetDefaults)
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 36)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(String(localized: "settings.haptics.title"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $infoTopic) { topic in
            SettingsInfoSheet(topic: topic, faceDownTimeout: Int(Self.faceDownTimeout))
        }
        .onChange(of: settings.isSecretGestureEnabled) { enabled in
            guard !enabled, isWaitingForGesture else { return }
            gestureTask?.cancel()
            gestureTask = nil
            isWaitingForGesture = false
            isTesting = false
        }
        .onDisappear {
            haptics.cancelPendingHaptics()
            gestureTask?.cancel()
            gestureTask = nil
            faceDownTestTask?.cancel()
            faceDownTestTask = nil
            gestureManager.stopMonitoring()
            isWaitingForGesture = false
            isTesting = false
            faceDownTest = .idle
        }
    }

    private func playStrengthSample() {
        guard !isTesting else { return }
        haptics.playCount(strengthSampleCount, completion: nil)
    }

    // The example from the grouping description (7 as 3, 3 and 1), always grouped so the row can be tried before it is switched on.
    private func playGroupingSample() {
        guard !isTesting, faceDownTest != .waiting else { return }
        haptics.playGroupedCount(testNumber, completion: nil)
    }

    // Waits for the phone to be put face down; after the timeout it stops and shows how to do it.
    private func startFaceDownTest() {
        guard !isTesting, faceDownTest != .waiting else { return }
        haptics.cancelPendingHaptics()
        faceDownTest = .waiting
        faceDownTestTask = Task { @MainActor in
            let result = await gestureManager.waitForScreenDownGesture(timeout: Self.faceDownTimeout)
            switch result {
            case .detected:
                faceDownTest = .detected
                // One short buzz: the phone felt it.
                haptics.playCount(1, completion: nil)
                try? await Task.sleep(seconds: 2)
                faceDownTest = .idle
            case .timedOut:
                faceDownTest = .idle
                infoTopic = .faceDownMissed
            case .cancelled:
                faceDownTest = .idle
            }
            faceDownTestTask = nil
        }
    }

    private func playPreview() {
        guard !isTesting, faceDownTest != .waiting else { return }
        isTesting = true

        if settings.isSecretGestureEnabled {
            isWaitingForGesture = true
            gestureTask = Task { @MainActor in
                let result = await gestureManager.waitForScreenDownGesture(timeout: Self.faceDownTimeout)
                isWaitingForGesture = false
                gestureTask = nil
                guard result == .detected else {
                    isTesting = false
                    if result == .timedOut { infoTopic = .faceDownMissed }
                    return
                }
                haptics.playCount(testNumber) {
                    isTesting = false
                }
            }
        } else {
            haptics.playCount(testNumber) {
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
