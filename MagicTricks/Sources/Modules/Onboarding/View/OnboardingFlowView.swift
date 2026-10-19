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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
        .overlay(alignment: .topTrailing) {
            if viewModel.step.isSkippable {
                Button(String(localized: "onboarding.skip"), action: viewModel.skip)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .transition(.opacity)
            }
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
        .offset(y: isDismissing && !reduceMotion ? 900 : 0)
        .opacity(isDismissing && reduceMotion ? 0 : 1)
        
        .animation(reduceMotion ? .easeOut(duration: 0.25) : .spring(response: 0.35, dampingFraction: 0.82), value: isDismissing)
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
            PaywallScreen(context: .general, onDismiss: dismissPaywall)
        }
    }

    private func dismissPaywall() {
        // The close button and a purchase can both end the paywall; finish only once.
        guard !isDismissing else { return }
        isDismissing = true
        Task {
            try? await Task.sleep(milliseconds: 300)
            viewModel.complete()
        }
    }
}
