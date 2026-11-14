//
//  OnboardingViewModel.swift
//  Magic Tricks
//
//  Created by Ross on 28/03/2026.
//

import Foundation

private let l10n = L10nDomain("onboarding.processing")

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var step: OnboardingStep = .welcome
    @Published var selectedGoals: Set<OnboardingGoal> = []

    private var preferences: OnboardingPreferenceManaging
    // A tester can end the onboarding before its paywall (TestFlight settings).
    private let skipsPaywall: () -> Bool
    private let onComplete: () -> Void
    private var didComplete = false

    init(
        preferences: OnboardingPreferenceManaging = AppPreferences.shared,
        skipsPaywall: @escaping () -> Bool = { AppBuildEnvironment.skipsOnboardingPaywall },
        onComplete: @escaping () -> Void
    ) {
        self.preferences = preferences
        self.skipsPaywall = skipsPaywall
        self.onComplete = onComplete
    }

    func advance() {
        guard let next = step.next else { return }
        if next == .paywall && skipsPaywall() {
            complete()
            return
        }
        step = next
    }

    func skip() {
        guard step.isSkippable else { return }
        if skipsPaywall() {
            complete()
            return
        }
        step = .paywall
    }

    func complete() {
        guard !didComplete else { return }
        didComplete = true
        preferences.hasCompletedOnboarding = true
        onComplete()
    }

    var loadingPhases: [String] {
        [
            loadingPhase1,
            String(localized: l10n("phase2")),
            String(localized: l10n("phase3")),
        ]
    }

    private var loadingPhase1: String {
        if selectedGoals.contains(.everywhere) {
            return String(localized: l10n("phase1.everywhere"))
        }
        let matched = selectedGoals.orderedCombinableGoals
        switch matched.count {
        case 0:
            return String(localized: l10n("phase1"))
        case 1:
            return String(localized: l10n("phase1.\(matched[0].rawValue)"))
        default:
            // Each goal contributes a short noun phrase; ListFormatter joins them with correct per-locale grammar.
            let fragments = matched.map { goal in
                String(localized: l10n("goalFragment.\(goal.rawValue)"))
            }
            let joined = ListFormatter().string(from: fragments) ?? fragments.joined(separator: ", ")
            return String(format: String(localized: l10n("phase1.combined")), joined)
        }
    }
}
