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

    func playCount(_ count: Int, completion: (() -> Void)? = nil) {
        if HapticPreferences.isGroupByThreeEnabled {
            playGroupedCountSignal(count, generator: impactGenerator, completion: completion)
        } else {
            playCountSignal(count, generator: impactGenerator, completion: completion)
        }
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
