//
//  OnboardingViewModel.swift
//  Magic Tricks
//
//  Created by Ross on 28/03/2026.
//

import Foundation
import SwiftUI

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var step: OnboardingStep = .welcome
    @Published var selectedGoals: Set<OnboardingGoal> = []

    private let onComplete: () -> Void

    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    func advance() {
        guard let next = step.next else { return }
        withAnimation(.easeOut(duration: 0.22)) {
            step = next
        }
    }

    func complete() {
        AppPreferences.shared.hasCompletedOnboarding = true
        onComplete()
    }

    var loadingPhases: [String] {
        [
            loadingPhase1,
            String(localized: "onboarding.processing.phase2"),
            String(localized: "onboarding.processing.phase3"),
        ]
    }

    private var loadingPhase1: String {
        if selectedGoals.contains(.everywhere) {
            return String(localized: "onboarding.processing.phase1.everywhere")
        }
        let matched = selectedGoals.orderedCombinableGoals
        switch matched.count {
        case 0:
            return String(localized: "onboarding.processing.phase1")
        case 1:
            return String(localized: String.LocalizationValue("onboarding.processing.phase1.\(matched[0].rawValue)"))
        default:
            // Each goal contributes a short noun phrase; ListFormatter joins them with
            // correct per-locale grammar ("A, B and C") instead of a phrase per goal combination.
            let fragments = matched.map {
                String(localized: String.LocalizationValue("onboarding.processing.goalFragment.\($0.rawValue)"))
            }
            let joined = ListFormatter().string(from: fragments) ?? fragments.joined(separator: ", ")
            return String(format: String(localized: "onboarding.processing.phase1.combined"), joined)
        }
    }
}
