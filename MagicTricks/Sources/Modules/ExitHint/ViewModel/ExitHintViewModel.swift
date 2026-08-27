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

    init(preferences: ExitHintPreferenceManaging = AppPreferences.shared) {
        self.preferences = preferences
    }

    var didLearnExitHint: Bool {
        get { preferences.didLearnExitHint }
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
        autoFadeTask?.cancel()
        hintOpacity = ExitHintOpacity.visible

        guard isVisible, didLearnExitHint else { return }

        autoFadeTask = Task {
            await pause(ExitHintFadeTiming.initialDelay)
            guard !Task.isCancelled else { return }

            hintOpacity = ExitHintOpacity.dimmed

            await pause(ExitHintFadeTiming.dimDuration)
            guard !Task.isCancelled else { return }

            hintOpacity = ExitHintOpacity.hidden

            await pause(ExitHintFadeTiming.hideDuration)
            guard !Task.isCancelled else { return }

            onAutoFadeComplete()
        }
    }

    func flashHint() {
        flashTask?.cancel()
        flashTask = Task {
            for _ in 0..<ExitHintFlash.repeatCount {
                flashBrightness = ExitHintFlash.peak
                await pause(ExitHintFlashTiming.holdAfterPeak)
                flashBrightness = ExitHintFlash.rest
                await pause(ExitHintFlashTiming.holdAfterRest)
            }
        }
    }

    func holdStarted() {
        cancelAutoFade()
        holdScale = ExitHintHoldScale.pressed
    }

    func holdCancelled() {
        holdScale = ExitHintHoldScale.released
    }

    func cancelAutoFade() {
        autoFadeTask?.cancel()
    }

    private func pause(_ duration: TimeInterval) async {
        try? await Task.sleep(seconds: duration)
    }
}
