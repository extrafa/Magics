//
//  ExitHintViewModel.swift
//  Magic Tricks
//
//  Created by Ross on 09/04/2026.
//

import SwiftUI

@MainActor
final class ExitHintViewModel: ObservableObject {
    @Published var hintOpacity = 1.0
    @Published var holdScale: CGFloat = 1.0
    @Published var flashBrightness: Double = 0.0
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

    func confirmHintDismiss(onConfirmExit: @escaping () -> Void) {
        didLearnExitHint = true
        isConfirmAlertPresented = false
        withAnimation(.easeOut(duration: 0.22)) {
            onConfirmExit()
        }
    }

    func configurePresentation(isVisible: Bool, isHintVisible: Binding<Bool>) {
        autoFadeTask?.cancel()
        hintOpacity = 1

        guard isVisible, didLearnExitHint else { return }

        autoFadeTask = Task {
            try? await Task.sleep(seconds: 2)
            guard !Task.isCancelled else { return }

            withAnimation(.easeOut(duration: 2.2)) {
                self.hintOpacity = 0.18
            }

            try? await Task.sleep(milliseconds: 2200)
            guard !Task.isCancelled else { return }

            // Fade to 0 within ExitHintView's own hierarchy — avoids triggering an
            // animation transaction on the parent view (which would merge with any
            // repeatForever animations on sibling views and cause a visual jerk).
            withAnimation(.easeOut(duration: 0.8)) {
                self.hintOpacity = 0
            }

            try? await Task.sleep(milliseconds: 800)
            guard !Task.isCancelled else { return }

            // Already at opacity 0 — set binding without animation so the parent
            // doesn't receive an animated transaction.
            isHintVisible.wrappedValue = false
        }
    }

    func flashHint() {
        flashTask?.cancel()
        flashTask = Task {
            for _ in 0..<2 {
                withAnimation(.easeOut(duration: 0.07)) {
                    self.flashBrightness = 0.30
                }
                try? await Task.sleep(milliseconds: 90)
                withAnimation(.easeIn(duration: 0.16)) {
                    self.flashBrightness = 0.0
                }
                try? await Task.sleep(milliseconds: 200)
            }
        }
    }

    func holdStarted() {
        cancelAutoFade()
        withAnimation(.easeInOut(duration: ExitHintZone.minimumPressDuration * 1.4)) {
            holdScale = 0.90
        }
    }

    func holdCancelled() {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.55)) {
            holdScale = 1.0
        }
    }

    func cancelAutoFade() {
        autoFadeTask?.cancel()
    }
}
