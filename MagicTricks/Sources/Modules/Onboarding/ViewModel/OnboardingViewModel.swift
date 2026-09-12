//
//  OnboardingViewModel.swift
//  Magic Tricks
//
//  Created by Ross on 28/03/2026.
//

import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var step: OnboardingStep = .welcome
    @Published var selectedGoals: Set<OnboardingGoal> = []

    private var preferences: OnboardingPreferenceManaging
    private let onComplete: () -> Void

    init(preferences: OnboardingPreferenceManaging = AppPreferences.shared, onComplete: @escaping () -> Void) {
        self.preferences = preferences
        self.onComplete = onComplete
    }

    func advance() {
        guard let next = step.next else { return }
        step = next
    }

    func complete() {
        preferences.hasCompletedOnboarding = true
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
            // Built as a String first - interpolating into a LocalizationValue literal makes it a %@ argument, not part of the key.
            let key: String = "onboarding.processing.phase1.\(matched[0].rawValue)"
            return String(localized: String.LocalizationValue(key))
        default:
            // Each goal contributes a short noun phrase; ListFormatter joins them with correct per-locale grammar.
            let fragments = matched.map { goal -> String in
                let key: String = "onboarding.processing.goalFragment.\(goal.rawValue)"
                return String(localized: String.LocalizationValue(key))
            }
            let joined = ListFormatter().string(from: fragments) ?? fragments.joined(separator: ", ")
            return String(format: String(localized: "onboarding.processing.phase1.combined"), joined)
        }
    }
}
