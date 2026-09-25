//
//  TimeControlSignalTransmitter.swift
//  Magic Tricks
//
//  Created by Ross on 23/08/2025.
//

import Foundation

@MainActor
protocol TimeControlSignalTransmitting {
    func transmit(
        second: Int,
        hundredths: Int,
        onPhaseChange: @escaping (TimeControlTransmissionPhase) -> Void
    ) async
    func cancel()
}

enum TimeControlTransmissionPhase {
    case waitingForStartTrigger
    case playingSeconds
    case waitingBetweenValues
    case waitingForHundredthsTrigger
    case playingHundredths
}

@MainActor
final class TimeControlSignalTransmitter: TimeControlSignalTransmitting {
    private let haptics: TimeHapticPlaying
    private let gestureManager: PhoneTiltGestureManager
    private let preferences: MotionPreferenceManaging

    private let automaticStartDelay: TimeInterval = 1
    private let sectionDelay: TimeInterval = 3

    private var pendingHapticCompletion: Completion?

    init(
        haptics: TimeHapticPlaying? = nil,
        preferences: MotionPreferenceManaging = AppPreferences.shared,
        gestureManager: PhoneTiltGestureManager? = nil
    ) {
        self.haptics = haptics ?? HapticManager.shared
        self.preferences = preferences
        self.gestureManager = gestureManager ?? PhoneTiltGestureManager(preferences: preferences)
    }

    func transmit(
        second: Int,
        hundredths: Int,
        onPhaseChange: @escaping (TimeControlTransmissionPhase) -> Void
    ) async {
        onPhaseChange(.waitingForStartTrigger)
        guard await waitForStartTrigger() else { return }

        onPhaseChange(.playingSeconds)
        await playTimeValue(second)

        onPhaseChange(.waitingBetweenValues)
        guard await waitSeconds(sectionDelay) else { return }

        if preferences.isSecretGestureEnabled {
            onPhaseChange(.waitingForHundredthsTrigger)
            guard await gestureManager.waitForScreenDownGesture() else { return }
        }

        onPhaseChange(.playingHundredths)
        await playTimeValue(hundredths)
    }

    func cancel() {
        gestureManager.stopMonitoring()
        haptics.cancelPendingHaptics()
        resumePendingHapticCompletion()
    }

    private func waitForStartTrigger() async -> Bool {
        if preferences.isSecretGestureEnabled {
            return await gestureManager.waitForScreenDownGesture()
        }

        return await waitSeconds(automaticStartDelay)
    }

    private func playTimeValue(_ value: Int) async {
        await withCheckedContinuation { continuation in
            pendingHapticCompletion = { continuation.resume() }
            haptics.playTimeValue(value, initialDelay: 0, usesGrouping: true) { [weak self] in
                self?.resumePendingHapticCompletion()
            }
        }
    }

    private func resumePendingHapticCompletion() {
        let completion = pendingHapticCompletion
        pendingHapticCompletion = nil
        completion?()
    }
}
