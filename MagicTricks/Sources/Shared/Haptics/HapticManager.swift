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

    var mediumImpactGenerator: UIImpactFeedbackGenerator {
        UIImpactFeedbackGenerator(style: HapticPreferences.intensity.feedbackStyle)
    }
    var heavyImpactGenerator: UIImpactFeedbackGenerator {
        UIImpactFeedbackGenerator(style: HapticPreferences.intensity.feedbackStyle)
    }
    private let notificationGenerator = UINotificationFeedbackGenerator()
    let enginePlayer: HapticEnginePlaying
    let scheduler: HapticScheduling

    init(
        enginePlayer: HapticEnginePlaying? = nil,
        scheduler: HapticScheduling? = nil
    ) {
        self.enginePlayer = enginePlayer ?? HapticEnginePlayer()
        self.scheduler = scheduler ?? HapticScheduler()
    }

    func handleScenePhase(_ phase: ScenePhase) {
        guard phase == .active else { return }
        restartEngineIfNeeded()
    }

    func playSuccessNotification() {
        notificationGenerator.notificationOccurred(.success)
    }

    func playColorCode(_ count: Int, completion: (() -> Void)? = nil) {
        playCountSignal(count, generator: mediumImpactGenerator, completion: completion)
    }

    func playTrainingDigit(_ digit: Int, completion: (() -> Void)? = nil) {
        if HapticPreferences.isGroupByThreeEnabled {
            playGroupedCountSignal(digit, generator: heavyImpactGenerator, completion: completion)
        } else {
            playCountSignal(digit, generator: heavyImpactGenerator, completion: completion)
        }
    }

    func playDigitSignal(_ digit: Int, initialDelay: TimeInterval = HapticTiming.initialDelay, completion: (() -> Void)? = nil) {
        playCountSignal(digit, initialDelay: initialDelay, generator: heavyImpactGenerator, completion: completion)
    }

    func playTimeValue(
        _ value: Int,
        initialDelay: TimeInterval = 0,
        usesGrouping: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        if usesGrouping && HapticPreferences.isGroupByThreeEnabled {
            playGroupedTimeValue(value, initialDelay: initialDelay, completion: completion)
        } else {
            playClassicTimeValue(value, initialDelay: initialDelay, completion: completion)
        }
    }
}

extension HapticManager: HapticEngineManaging {}
extension HapticManager: HapticNotificationPlaying {}
extension HapticManager: CountHapticPlaying {}
extension HapticManager: TimeHapticPlaying {}
