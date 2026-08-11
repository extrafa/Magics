//
//  OnboardingFlowView.swift
//  Magic Tricks
//
//  Created by Ross on 28/03/2026.
//

import SwiftUI

struct OnboardingFlowView: View {
    @StateObject private var viewModel: OnboardingViewModel
    @State private var isDismissing = false

    init(onComplete: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(onComplete: onComplete))
    }

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()

            currentScreen
                .id(viewModel.step)
                .transition(.opacity)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            Group {
                if viewModel.step >= 1 && viewModel.step <= 4 {
                    OnboardingProgressBar(step: viewModel.step, total: 4)
                        .padding(.horizontal, 24)
                        .padding(.top, 14)
                        .padding(.bottom, 10)
                        .background(Color.background)
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.3), value: viewModel.step)
        }
        .offset(y: isDismissing ? 900 : 0)
        .fontDesign(.rounded)
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: isDismissing)
        .animation(.easeOut(duration: 0.22), value: viewModel.step)
    }

    // MARK: Flow
    // 0 — Welcome
    // 1 — Goal
    // 2 — Feature: No props
    // 3 — Feature: Instructions
    // 4 — Feature: Vibrations
    // 5 — Processing
    // 6 — Paywall

    @ViewBuilder
    private var currentScreen: some View {
        switch viewModel.step {
        case 0:
            OBWelcomeScreen(onContinue: viewModel.advance)
        case 1:
            OBGoalScreen(selectedGoals: $viewModel.selectedGoals, onContinue: viewModel.advance)
        case 2:
            OBFeatureSlideScreen(feature: .noProps, goals: viewModel.selectedGoals, onContinue: viewModel.advance)
        case 3:
            OBFeatureSlideScreen(feature: .instructions, goals: [], onContinue: viewModel.advance)
        case 4:
            OBFeatureSlideScreen(feature: .vibrations, goals: [], onContinue: viewModel.advance)
        case 5:
            OBProcessingScreen(phases: viewModel.loadingPhases, onComplete: viewModel.advance)
        case 6:
            OBPaywallScreen(onDismiss: dismissPaywall)
        default:
            EmptyView()
        }
    }

    private func dismissPaywall() {
        isDismissing = true
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            viewModel.complete()
        }
    }
}
