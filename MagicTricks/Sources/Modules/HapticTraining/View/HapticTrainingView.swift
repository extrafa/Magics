//
//  HapticTrainingView.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import SwiftUI

struct HapticTrainingView: View {
    @StateObject private var viewModel: HapticTrainingViewModel
    @State private var answerText = ""
    @FocusState private var isAnswerFocused: Bool

    private let mode: HapticTrainingMode

    init(mode: HapticTrainingMode = .digits) {
        self.mode = mode
        _viewModel = StateObject(wrappedValue: HapticTrainingViewModel(mode: mode))
    }

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()

            VStack(spacing: 18) {
                signalDeck
                answerSection
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
    }

    private var signalDeck: some View {
        VStack(spacing: 18) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(mode.accentColor.opacity(0.16))
                        .frame(width: 92, height: 92)

                    Image(systemName: mode.systemIcon)
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(mode.accentColor)
                }

                Text(mode.navigationTitle)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(Color.primaryText)

                Text(mode.subtitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primaryText.opacity(0.54))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .frame(height: 22)
            }

            Button(action: playSignal) {
                Label(mode.playButtonTitle, systemImage: "dot.radiowaves.left.and.right")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(PrimaryTrickButtonStyle(color: .button))
            .allowsHitTesting(!viewModel.isPlaying)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(deckBackground)
    }

    private var deckBackground: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(Color.grayCard)
            .overlay {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(Color.grayBorder, lineWidth: 1)
            }
    }

    private var answerSection: some View {
        HapticAnswerSectionView(
            mode: mode,
            hasPlayed: viewModel.hasPlayed,
            isPlaying: viewModel.isPlaying,
            result: viewModel.result,
            canSubmitAnswer: canSubmitAnswer,
            answerText: $answerText,
            isAnswerFocused: $isAnswerFocused,
            onAnswerChange: submitAnswerIfNeeded,
            onSubmit: submitExplicit
        )
    }

    private var canSubmitAnswer: Bool {
        viewModel.hasPlayed && viewModel.result == nil && !answerText.isEmpty && Int(answerText) != nil
    }

    private func playSignal() {
        guard !viewModel.isPlaying else { return }

        if viewModel.result != nil || viewModel.hasPlayed {
            startNewRound()
        }

        answerText = ""
        Task {
            let playedValue = viewModel.targetValue
            await viewModel.playSignal()
            if playedValue == 1 {
                // single-pulse signal — brief delay so the keyboard doesn't pop before the vibration settles
                try? await Task.sleep(for: .milliseconds(250))
            }
            isAnswerFocused = viewModel.result == nil
        }
    }

    private func submitAnswerIfNeeded(from value: String) {
        let maxDigits = 1
        let filtered = String(value.filter(\.isNumber).prefix(maxDigits))
        if answerText != filtered {
            answerText = filtered
            return
        }
        guard viewModel.hasPlayed, viewModel.result == nil else { return }
        if let number = Int(filtered) {
            viewModel.submitGuess(number)
        }
    }

    private func submitExplicit() {
        guard let number = Int(answerText) else { return }
        viewModel.submitGuess(number)
    }

    private func startNewRound() {
        viewModel.startNewRound()
        answerText = ""
        isAnswerFocused = false
    }
}

#Preview {
    HapticTrainingView()
}
