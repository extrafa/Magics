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
    @Published var isPaywallOverlayPresented = false

    private var pendingFlow: FullScreenFlow?
    private let preferences: AppPreferences
    private static let ratingTriggerCount = 3

    init(preferences: AppPreferences = .shared) {
        self.preferences = preferences
    }

    func recordTrickClose() {
        guard !preferences.hasRespondedToRating else { return }
        if let until = preferences.ratingSnoozedUntil, until > Date() { return }
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

    func presentPaywallOverlay() {
        isPaywallOverlayPresented = true
    }

    func dismissPaywallOverlay() {
        isPaywallOverlayPresented = false
    }

    func openStartFlow(for trick: Trick) {
        if hasSeenTrick(trick) {
            activeFlow = .trick(trick: trick)
        } else {
            activeSheet = .instructionFirstLaunch(instruction: trick.instruction, trick: trick)
        }
    }

    func markTrickAsSeen(_ trick: Trick) {
        var seen = preferences.seenTrickIds
        let id = trick.id.rawValue
        guard !seen.contains(id) else { return }
        seen.append(id)
        preferences.seenTrickIds = seen
    }

    func startTrickAfterInstruction(_ trick: Trick) {
        markTrickAsSeen(trick)
        pendingFlow = .trick(trick: trick)
        activeSheet = nil
    }

    func sheetDidDismiss() {
        guard let pendingFlow else { return }
        self.pendingFlow = nil
        activeFlow = pendingFlow
    }

    private func hasSeenTrick(_ trick: Trick) -> Bool {
        preferences.seenTrickIds.contains(trick.id.rawValue)
    }
}
