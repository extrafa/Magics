//
//  OnboardingState.swift
//  Magic Tricks
//
//  Created by Ross on 28/03/2026.
//

import Foundation

private let goalKey = L10nDomain("onboarding.goal")

enum OnboardingStep: Int, CaseIterable {
    case welcome, goal, noProps, instructions, vibrations, processing, paywall

    // Steps that show the progress bar, in order - the rest (welcome, processing, paywall) don't get one.
    static let progressSteps: [OnboardingStep] = [.goal, .noProps, .instructions, .vibrations]

    // 1-based position and total count among `progressSteps`, or nil if this step has no progress bar.
    var progress: (step: Int, total: Int)? {
        guard let index = Self.progressSteps.firstIndex(of: self) else { return nil }
        return (index + 1, Self.progressSteps.count)
    }

    // The loading screen and the paywall itself have nothing left to skip to.
    var isSkippable: Bool { self != .processing && self != .paywall }

    var next: OnboardingStep? {
        OnboardingStep(rawValue: rawValue + 1)
    }
}

enum OnboardingGoal: String, CaseIterable, Hashable {
    case parties, dates, work, family, everywhere

    // The goals that combine into a joint phrase (.everywhere is its own dedicated case), in a fixed display order.
    static let combinable: [OnboardingGoal] = [.parties, .dates, .work, .family]

    var emoji: String {
        switch self {
        case .parties: "🎉"
        case .dates: "🍷"
        case .work: "💼"
        case .family: "👨‍👩‍👧"
        case .everywhere: "🌍"
        }
    }

    var localizedTitle: String {
        switch self {
        case .parties: String(localized: goalKey("parties"))
        case .dates: String(localized: goalKey("dates"))
        case .work: String(localized: goalKey("work"))
        case .family: String(localized: goalKey("family"))
        case .everywhere: String(localized: goalKey("everywhere"))
        }
    }
}

extension Set where Element == OnboardingGoal {
    // One tap on a goal row. "Everywhere" is all goals at once; while it is on, the other rows look unticked, so a tap
    // on one of them means "just this one". Ticking all four others turns into "Everywhere".
    func toggled(_ goal: OnboardingGoal) -> Set<OnboardingGoal> {
        if goal == .everywhere {
            return contains(.everywhere) ? [] : Set(OnboardingGoal.allCases)
        }
        if contains(.everywhere) { return [goal] }
        var result = self
        if result.contains(goal) {
            result.remove(goal)
        } else {
            result.insert(goal)
            if result.isSuperset(of: Set(OnboardingGoal.combinable)) { return Set(OnboardingGoal.allCases) }
        }
        return result
    }

    // Combinable goals in this set, in fixed display order - for building a dynamic catalog key or fragment list.
    var orderedCombinableGoals: [OnboardingGoal] {
        OnboardingGoal.combinable.filter(contains)
    }
}
