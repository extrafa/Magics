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
            Color.backgroundScreen.ignoresSafeArea()

            currentScreen
                .id(viewModel.step)
                .transition(.opacity)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            Group {
                if let progress = viewModel.step.progress {
                    OnboardingProgressBar(step: progress.step, total: progress.total)
                        .padding(.horizontal, 24)
                        .padding(.top, 14)
                        .padding(.bottom, 10)
                        .background(Color.backgroundScreen)
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.3), value: viewModel.step)
        }
        .offset(y: isDismissing ? 900 : 0)
        
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: isDismissing)
        .animation(.easeOut(duration: 0.22), value: viewModel.step)
    }

    // MARK: Flow

    @ViewBuilder
    private var currentScreen: some View {
        switch viewModel.step {
        case .welcome:
            OnboardingWelcomeScreen(onContinue: viewModel.advance)
        case .goal:
            OnboardingGoalScreen(selectedGoals: $viewModel.selectedGoals, onContinue: viewModel.advance)
        case .noProps:
            OnboardingFeatureSlideScreen(feature: .noProps, goals: viewModel.selectedGoals, onContinue: viewModel.advance)
        case .instructions:
            OnboardingFeatureSlideScreen(feature: .instructions, goals: [], onContinue: viewModel.advance)
        case .vibrations:
            OnboardingFeatureSlideScreen(feature: .vibrations, goals: [], onContinue: viewModel.advance)
        case .processing:
            OnboardingProcessingScreen(phases: viewModel.loadingPhases, onComplete: viewModel.advance)
        case .paywall:
            OnboardingPaywallScreen(onDismiss: dismissPaywall)
        }
    }

    private func dismissPaywall() {
        isDismissing = true
        Task {
            try? await Task.sleep(milliseconds: 300)
            viewModel.complete()
        }
    }
}
