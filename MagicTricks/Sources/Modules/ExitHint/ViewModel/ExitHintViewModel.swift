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
    @Published var isConfirmSheetPresented = false

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
        !didLearnExitHint && !isConfirmSheetPresented
    }

    func presentConfirmation() {
        guard !didLearnExitHint else { return }
        isConfirmSheetPresented = true
    }

    func confirmHintDismiss(onConfirmExit: @escaping () -> Void) {
        didLearnExitHint = true
        isConfirmSheetPresented = false
        withAnimation(.easeOut(duration: 0.22)) {
            onConfirmExit()
        }
    }

    func cancelConfirmation() {
        isConfirmSheetPresented = false
    }

    func configurePresentation(isVisible: Bool, isHintVisible: Binding<Bool>) {
        autoFadeTask?.cancel()
        hintOpacity = 1

        guard isVisible, didLearnExitHint else { return }

        autoFadeTask = Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeOut(duration: 2.2)) {
                self.hintOpacity = 0.18
            }

            try? await Task.sleep(for: .milliseconds(2200))
            withAnimation(.easeOut(duration: 0.8)) {
                isHintVisible.wrappedValue = false
            }
        }
    }

    func flashHint() {
        flashTask?.cancel()
        flashTask = Task {
            for _ in 0..<2 {
                withAnimation(.easeOut(duration: 0.14)) {
                    self.hintOpacity = 0.62
                }
                try? await Task.sleep(for: .milliseconds(140))
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.hintOpacity = 1
                }
                try? await Task.sleep(for: .milliseconds(120))
            }
        }
    }

    func cancelAutoFade() {
        autoFadeTask?.cancel()
    }
}
