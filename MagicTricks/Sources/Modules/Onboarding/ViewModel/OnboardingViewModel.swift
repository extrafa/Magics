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
            // Interpolating directly into a String.LocalizationValue literal turns the
            // interpolated part into a %@ format argument instead of part of the key, so the
            // key is built as a plain String first (see OBFeatureSlideScreen.noPropsSubtitle(for:)).
            let key: String = "onboarding.processing.phase1.\(matched[0].rawValue)"
            return String(localized: String.LocalizationValue(key))
        default:
            // Each goal contributes a short noun phrase; ListFormatter joins them with
            // correct per-locale grammar ("A, B and C") instead of a phrase per goal combination.
            let fragments = matched.map { goal -> String in
                let key: String = "onboarding.processing.goalFragment.\(goal.rawValue)"
                return String(localized: String.LocalizationValue(key))
            }
            let joined = ListFormatter().string(from: fragments) ?? fragments.joined(separator: ", ")
            return String(format: String(localized: "onboarding.processing.phase1.combined"), joined)
        }
    }
}
