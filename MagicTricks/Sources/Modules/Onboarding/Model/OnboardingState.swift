import Foundation

enum OnboardingGoal: CaseIterable, Identifiable, Hashable {
    case parties, dates, work, family, everywhere
    var id: Self { self }

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
