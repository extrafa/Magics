//
//  AppFlowCoordinator.swift
//  Magic Tricks
//
//  Created by Ross on 11/01/2026.
//

import Foundation

@MainActor
final class AppFlowCoordinator: ObservableObject {

    @Published var activeFlow: FullScreenFlow?
    @Published var activeSheet: SheetFlow?

    private let preferences = AppPreferences.shared
    private static let ratingTriggerCount = 3

    func recordTrickClose() {
        guard !preferences.hasRespondedToRating else { return }
        preferences.trickLaunchCount += 1
        if preferences.trickLaunchCount >= Self.ratingTriggerCount {
            preferences.trickLaunchCount = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
                guard let self, self.activeFlow == nil, self.activeSheet == nil else { return }
                self.activeSheet = .rateApp
            }
        }
    }

    func open(trick: Trick) {
        activeFlow = .trick(trick: trick)
    }

    func open(instruction: Instruction) {
        activeSheet = .instruction(instruction: instruction)
    }

    func openPaywall() {
        activeFlow = .paywall
    }

    func openStartFlow(for trick: Trick) {
        if hasSeenTrick(trick) {
            activeFlow = .trick(trick: trick)
        } else {
            activeSheet = .instructionFirstLaunch(instruction: trick.instruction, trick: trick)
        }
    }

    func markTrickAsSeen(_ trick: Trick) {
        var seen = UserDefaults.standard.stringArray(forKey: "seenTrickIds") ?? []
        let id = String(describing: trick.id)
        guard !seen.contains(id) else { return }
        seen.append(id)
        UserDefaults.standard.set(seen, forKey: "seenTrickIds")
    }

    private func hasSeenTrick(_ trick: Trick) -> Bool {
        let seen = UserDefaults.standard.stringArray(forKey: "seenTrickIds") ?? []
        return seen.contains(String(describing: trick.id))
    }
}
