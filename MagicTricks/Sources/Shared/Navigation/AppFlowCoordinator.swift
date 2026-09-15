//
//  AppFlowCoordinator.swift
//  Magic Tricks
//
//  Created by Ross on 11/01/2026.
//

import Foundation

@MainActor
final class AppFlowCoordinator: ObservableObject {

    @Published var activeFlow: FullScreenFlow? {
        didSet {
            if case .trick = oldValue, activeFlow == nil {
                recordTrickClose()
            }
        }
    }
    @Published var activeSheet: SheetFlow?
    @Published var isPaywallOverlayPresented = false

    private var pendingFlow: FullScreenFlow?
    private var preferences: FlowPreferenceManaging
    private let scheduler: DelayedActionScheduling
    private let store: StoreManager
    private static let ratingTriggerCount = 3

    init(
        store: StoreManager,
        preferences: FlowPreferenceManaging = AppPreferences.shared,
        scheduler: DelayedActionScheduling = DispatchQueueScheduler()
    ) {
        self.store = store
        self.preferences = preferences
        self.scheduler = scheduler
    }

    func recordTrickClose() {
        guard !preferences.hasRespondedToRating else { return }
        if let until = preferences.ratingSnoozedUntil, until > Date() { return }
        preferences.trickLaunchCount += 1
        if preferences.trickLaunchCount >= Self.ratingTriggerCount {
            scheduler.schedule(after: 0.7) { [weak self] in
                guard let self, self.activeFlow == nil, self.activeSheet == nil else { return }
                self.preferences.trickLaunchCount = 0
                self.activeSheet = .rateApp
            }
        }
    }

    func open(instruction trick: Trick) {
        if isLocked(trick) {
            openPaywall()
        } else {
            activeSheet = .instruction(instruction: trick.instruction)
        }
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
        guard !isLocked(trick) else {
            openPaywall()
            return
        }
        if hasSeenTrick(trick) {
            activeFlow = .trick(trick: trick)
        } else {
            activeSheet = .instructionFirstLaunch(instruction: trick.instruction, trick: trick)
        }
    }

    func resetRatingState() {
        preferences.hasRespondedToRating = false
        preferences.trickLaunchCount = 0
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

    private func isLocked(_ trick: Trick) -> Bool {
        trick.id.requiresPro && !store.hasProAccess
    }
}
