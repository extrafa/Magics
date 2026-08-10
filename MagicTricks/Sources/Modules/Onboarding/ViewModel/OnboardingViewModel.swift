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
    @Published var step: Int = 0
    @Published var selectedGoals: Set<OnboardingGoal> = []

    private let onComplete: () -> Void

    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    func advance() {
        withAnimation(.easeOut(duration: 0.22)) {
            step += 1
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
        ]
    }

    private var loadingPhase1: String {
        if selectedGoals.contains(.everywhere) || selectedGoals == Set([.parties, .dates, .work, .family]) { return String(localized: "onboarding.processing.phase1.everywhere") }
        if selectedGoals == Set([.parties])                              { return String(localized: "onboarding.processing.phase1.parties") }
        if selectedGoals == Set([.dates])                                { return String(localized: "onboarding.processing.phase1.dates") }
        if selectedGoals == Set([.work])                                 { return String(localized: "onboarding.processing.phase1.work") }
        if selectedGoals == Set([.family])                               { return String(localized: "onboarding.processing.phase1.family") }
        if selectedGoals == Set([.parties, .dates])                      { return String(localized: "onboarding.processing.phase1.parties.dates") }
        if selectedGoals == Set([.parties, .work])                       { return String(localized: "onboarding.processing.phase1.parties.work") }
        if selectedGoals == Set([.parties, .family])                     { return String(localized: "onboarding.processing.phase1.parties.family") }
        if selectedGoals == Set([.dates, .work])                         { return String(localized: "onboarding.processing.phase1.dates.work") }
        if selectedGoals == Set([.dates, .family])                       { return String(localized: "onboarding.processing.phase1.dates.family") }
        if selectedGoals == Set([.work, .family])                        { return String(localized: "onboarding.processing.phase1.work.family") }
        if selectedGoals == Set([.parties, .dates, .work])               { return String(localized: "onboarding.processing.phase1.parties.dates.work") }
        if selectedGoals == Set([.parties, .dates, .family])             { return String(localized: "onboarding.processing.phase1.parties.dates.family") }
        if selectedGoals == Set([.parties, .work, .family])              { return String(localized: "onboarding.processing.phase1.parties.work.family") }
        if selectedGoals == Set([.dates, .work, .family])                { return String(localized: "onboarding.processing.phase1.dates.work.family") }
        return String(localized: "onboarding.processing.phase1")
    }
}
