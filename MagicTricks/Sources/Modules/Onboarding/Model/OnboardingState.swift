//
//  OnboardingState.swift
//  Magic Tricks
//
//  Created by Ross on 28/03/2026.
//

import Foundation

enum OnboardingStep: Int, CaseIterable {
    case welcome, goal, noProps, instructions, vibrations, processing, paywall

    // The steps that show the progress bar, in order - screens outside this
    // list (welcome, processing, paywall) don't get one.
    static let progressSteps: [OnboardingStep] = [.goal, .noProps, .instructions, .vibrations]

    // 1-based position and total count among `progressSteps`, or nil if this step has no progress bar.
    var progress: (step: Int, total: Int)? {
        guard let index = Self.progressSteps.firstIndex(of: self) else { return nil }
        return (index + 1, Self.progressSteps.count)
    }

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
        case .parties: String(localized: "onboarding.goal.parties")
        case .dates: String(localized: "onboarding.goal.dates")
        case .work: String(localized: "onboarding.goal.work")
        case .family: String(localized: "onboarding.goal.family")
        case .everywhere: String(localized: "onboarding.goal.everywhere")
        }
    }
}

extension Set where Element == OnboardingGoal {
    // The combinable goals actually in this set, in the fixed display order - e.g. for building a
    // "onboarding.foo.<parties>.<dates>" catalog key or a list of per-goal fragments to join.
    var orderedCombinableGoals: [OnboardingGoal] {
        OnboardingGoal.combinable.filter(contains)
    }
}

enum OnboardingPainPoint: CaseIterable, Identifiable, Hashable {
    case tooHard, needsProps, forgetUnderPressure, scaredOfBeingCaught, noTricksForMe, noTime
    var id: Self { self }

    var emoji: String {
        switch self {
        case .tooHard: "😰"
        case .needsProps: "🃏"
        case .forgetUnderPressure: "🧠"
        case .scaredOfBeingCaught: "😬"
        case .noTricksForMe: "🤷"
        case .noTime: "⏱"
        }
    }

    var localizedTitle: String {
        switch self {
        case .tooHard: String(localized: "onboarding.pain.tooHard")
        case .needsProps: String(localized: "onboarding.pain.needsProps")
        case .forgetUnderPressure: String(localized: "onboarding.pain.forgetUnderPressure")
        case .scaredOfBeingCaught: String(localized: "onboarding.pain.scaredOfBeingCaught")
        case .noTricksForMe: String(localized: "onboarding.pain.noTricksForMe")
        case .noTime: String(localized: "onboarding.pain.noTime")
        }
    }

    var localizedSolution: String {
        switch self {
        case .tooHard: String(localized: "onboarding.solution.tooHard")
        case .needsProps: String(localized: "onboarding.solution.needsProps")
        case .forgetUnderPressure: String(localized: "onboarding.solution.forgetUnderPressure")
        case .scaredOfBeingCaught: String(localized: "onboarding.solution.scaredOfBeingCaught")
        case .noTricksForMe: String(localized: "onboarding.solution.noTricksForMe")
        case .noTime: String(localized: "onboarding.solution.noTime")
        }
    }
}
