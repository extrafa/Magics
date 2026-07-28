import Foundation
import SwiftUI

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var step: Int = 0
    @Published var selectedGoal: OnboardingGoal?

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
        switch selectedGoal {
        case .parties:    String(localized: "onboarding.processing.phase1.parties")
        case .dates:      String(localized: "onboarding.processing.phase1.dates")
        case .work:       String(localized: "onboarding.processing.phase1.work")
        case .family:     String(localized: "onboarding.processing.phase1.family")
        case .everywhere: String(localized: "onboarding.processing.phase1.everywhere")
        case nil:         String(localized: "onboarding.processing.phase1")
        }
    }
}
