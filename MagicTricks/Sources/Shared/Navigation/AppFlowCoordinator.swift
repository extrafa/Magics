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
    private(set) var paywallOverlayContext: PaywallContext = .general
    // Set by restartOnboarding(); the app shows the onboarding over everything and clears it.
    @Published private(set) var isOnboardingRequested = false

    private var pendingFlow: FullScreenFlow?
    private var preferences: FlowPreferenceManaging
    private let scheduler: DelayedActionScheduling
    private let store: StoreManager
    private let now: () -> Date
    private static let ratingTriggerCount = 3
    private static let ratingMinInstallAge: TimeInterval = 3 * 24 * 60 * 60

    init(
        store: StoreManager,
        preferences: FlowPreferenceManaging = AppPreferences.shared,
        scheduler: DelayedActionScheduling = DispatchQueueScheduler(),
        now: @escaping () -> Date = Date.init
    ) {
        self.store = store
        self.preferences = preferences
        self.scheduler = scheduler
        self.now = now
        if self.preferences.firstLaunchDate == nil {
            self.preferences.firstLaunchDate = now()
        }
    }

    func recordTrickClose() {
        guard !preferences.hasRespondedToRating else { return }
        preferences.trickLaunchCount += 1
        // The count keeps growing during the first days, so the sheet comes on the first close after them.
        guard hasRatingInstallAge else { return }
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
            openPaywall(context: .trick(trick.id))
        } else {
            activeSheet = .instruction(instruction: trick.instruction)
        }
    }

    func openPaywall(context: PaywallContext = .general) {
        activeFlow = .paywall(context: context)
    }

    func presentPaywallOverlay(context: PaywallContext = .general) {
        paywallOverlayContext = context
        isPaywallOverlayPresented = true
    }

    func dismissPaywallOverlay() {
        isPaywallOverlayPresented = false
    }

    func openStartFlow(for trick: Trick) {
        guard !isLocked(trick) else {
            openPaywall(context: .trick(trick.id))
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
        // A tester who resets the sheet wants to see it again, not wait three days.
        preferences.firstLaunchDate = .distantPast
    }

    // TestFlight: forgets what the first run remembers, so the onboarding, the first-trick instructions and the exit tip show again.
    func restartOnboarding() {
        preferences.hasCompletedOnboarding = false
        preferences.seenTrickIds = []
        preferences.didLearnExitHint = false
        resetRatingState()
        isOnboardingRequested = true
    }

    func onboardingPresented() {
        isOnboardingRequested = false
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

    private var hasRatingInstallAge: Bool {
        guard let first = preferences.firstLaunchDate else { return false }
        return now().timeIntervalSince(first) >= Self.ratingMinInstallAge
    }

    private func hasSeenTrick(_ trick: Trick) -> Bool {
        preferences.seenTrickIds.contains(trick.id.rawValue)
    }

    private func isLocked(_ trick: Trick) -> Bool {
        store.isLocked(trick.id)
    }
}
