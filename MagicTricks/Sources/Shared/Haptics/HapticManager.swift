//
//  HapticManager.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import SwiftUI
import UIKit

@MainActor
final class HapticManager {
    static let shared = HapticManager()

    let impactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    let enginePlayer: HapticEnginePlaying
    let scheduler: HapticScheduling
    let preferences: HapticPreferenceManaging

    init(
        enginePlayer: HapticEnginePlaying? = nil,
        scheduler: HapticScheduling? = nil,
        preferences: HapticPreferenceManaging = AppPreferences.shared
    ) {
        self.preferences = preferences
        self.enginePlayer = enginePlayer ?? HapticEnginePlayer()
        self.scheduler = scheduler ?? HapticScheduler(preferences: preferences)
    }

    func handleScenePhase(_ phase: ScenePhase) {
        guard phase == .active else { return }
        restartEngineIfNeeded()
    }

    func playSuccessNotification() {
        notificationGenerator.notificationOccurred(.success)
    }

    func cancelPendingHaptics() {
        scheduler.cancelAll()
        enginePlayer.stop()
    }

    func playCount(_ count: Int, completion: Completion? = nil) {
        cancelPendingHaptics()
        let timings = HapticTimings(preferences: preferences)
        if timings.isGroupByThreeEnabled {
            playGroupedCountSignal(count, generator: impactGenerator, timings: timings, completion: completion)
        } else {
            playCountSignal(count, generator: impactGenerator, timings: timings, completion: completion)
        }
    }

    func playTimeValue(
        _ value: Int,
        initialDelay: TimeInterval = 0,
        usesGrouping: Bool = true,
        completion: Completion? = nil
    ) {
        cancelPendingHaptics()
        let timings = HapticTimings(preferences: preferences)
        if usesGrouping && timings.isGroupByThreeEnabled {
            playGroupedTimeValue(value, initialDelay: initialDelay, timings: timings, completion: completion)
        } else {
            playClassicTimeValue(value, initialDelay: initialDelay, timings: timings, completion: completion)
        }
    }
}

extension HapticManager: HapticEngineManaging {}
extension HapticManager: HapticNotificationPlaying {}
extension HapticManager: CountHapticPlaying {}
extension HapticManager: TimeHapticPlaying {}
