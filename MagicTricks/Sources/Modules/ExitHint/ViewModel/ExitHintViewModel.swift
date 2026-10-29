//
//  ExitHintViewModel.swift
//  Magic Tricks
//
//  Created by Ross on 09/04/2026.
//

import Foundation

@MainActor
final class ExitHintViewModel: ObservableObject {
    @Published var hintOpacity = ExitHintOpacity.visible
    @Published var holdScale: CGFloat = ExitHintHoldScale.released
    @Published var flashBrightness = ExitHintFlash.rest
    @Published var isConfirmAlertPresented = false
    @Published var isSwipeAlertPresented = false

    private var autoFadeTask: Task<Void, Never>?
    private var flashTask: Task<Void, Never>?
    private var preferences: ExitHintPreferenceManaging
    private let skipsTraining: Bool
    private let fadeSchedule: ExitHintFadeSchedule
    // Set while an auto fade is unfinished, so a paused fade can pick up where it stopped.
    private var fadeCompletion: Completion?

    init(
        preferences: ExitHintPreferenceManaging = AppPreferences.shared,
        skipsTraining: Bool = false,
        fadeSchedule: ExitHintFadeSchedule = ExitHintFadeSchedule()
    ) {
        self.preferences = preferences
        self.skipsTraining = skipsTraining
        self.fadeSchedule = fadeSchedule
    }

    deinit {
        autoFadeTask?.cancel()
        flashTask?.cancel()
    }

    var didLearnExitHint: Bool {
        get { skipsTraining || preferences.didLearnExitHint }
        set { preferences.didLearnExitHint = newValue }
    }

    var shouldBlockInteraction: Bool {
        !didLearnExitHint && !isConfirmAlertPresented && !isSwipeAlertPresented
    }

    func presentConfirmation() {
        guard !didLearnExitHint else { return }
        isConfirmAlertPresented = true
    }

    func presentSwipeAlert() {
        guard !didLearnExitHint else { return }
        isSwipeAlertPresented = true
    }

    func confirmHintDismiss() {
        didLearnExitHint = true
        isConfirmAlertPresented = false
    }

    func configurePresentation(isVisible: Bool, onAutoFadeComplete: @escaping () -> Void) {
        cancelAutoFade()
        hintOpacity = ExitHintOpacity.visible

        guard isVisible, didLearnExitHint else { return }

        fadeCompletion = onAutoFadeComplete
        runAutoFade()
    }

    // Continues from the current phase, so a resumed fade doesn't start over.
    private func runAutoFade() {
        autoFadeTask?.cancel()
        autoFadeTask = Task { [weak self] in
            guard let self else { return }

            if hintOpacity == ExitHintOpacity.visible {
                await pause(fadeSchedule.initialDelay)
                guard !Task.isCancelled else { return }
                hintOpacity = ExitHintOpacity.dimmed
            }

            if hintOpacity == ExitHintOpacity.dimmed {
                await pause(fadeSchedule.dimDuration)
                guard !Task.isCancelled else { return }
                hintOpacity = ExitHintOpacity.hidden
            }

            await pause(fadeSchedule.hideDuration)
            guard !Task.isCancelled else { return }

            let completion = fadeCompletion
            fadeCompletion = nil
            completion?()
        }
    }

    func flashHint() {
        flashTask?.cancel()
        flashTask = Task { [weak self] in
            guard let self else { return }
            for _ in 0..<ExitHintFlash.repeatCount {
                guard !Task.isCancelled else { return }
                flashBrightness = ExitHintFlash.peak
                await pause(ExitHintFlashTiming.holdAfterPeak)
                guard !Task.isCancelled else { return }
                flashBrightness = ExitHintFlash.rest
                await pause(ExitHintFlashTiming.holdAfterRest)
            }
        }
    }

    // The hint must not fade under a finger, but a touch that ends without exiting lets the fade go on.
    func holdStarted() {
        autoFadeTask?.cancel()
        holdScale = ExitHintHoldScale.pressed
    }

    func holdCancelled() {
        holdScale = ExitHintHoldScale.released
        guard fadeCompletion != nil else { return }
        runAutoFade()
    }

    func cancelAutoFade() {
        autoFadeTask?.cancel()
        fadeCompletion = nil
    }

    func cancelAll() {
        cancelAutoFade()
        flashTask?.cancel()
    }

    private func pause(_ duration: TimeInterval) async {
        try? await Task.sleep(seconds: duration)
    }
}
