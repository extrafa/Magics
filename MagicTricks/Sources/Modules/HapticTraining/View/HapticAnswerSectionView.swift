//
//  HapticAnswerSectionView.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import SwiftUI

struct HapticAnswerSectionView: View {

    let mode: HapticTrainingMode
    let hasPlayed: Bool
    let isPlaying: Bool
    let result: HapticTrainingViewModel.GuessResult?
    let canSubmitAnswer: Bool
    @Binding var answerText: String
    var isAnswerFocused: FocusState<Bool>.Binding
    let onAnswerChange: (String) -> Void
    let onSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "training.answer.title"))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primaryText.opacity(0.58))

            // Keyboard appears programmatically after the signal; direct taps are blocked so the
            // user can't open the keyboard before playing.
            TextField(isAnswerFocused.wrappedValue ? "" : mode.inputPlaceholder, text: $answerText)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(Color.primaryText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .focused(isAnswerFocused)
                .allowsHitTesting(false)
                .frame(height: 50)
                .background(answerFieldBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(answerFieldStroke, lineWidth: 1.2)
                }
                .opacity(hasPlayed && !isPlaying || result != nil ? 1 : 0.42)
                .onChange(of: answerText) { newValue in
                    onAnswerChange(newValue)
                }

            Text(resultLabel)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(resultColor)
                .frame(maxWidth: .infinity, minHeight: 20, alignment: .center)
        }
    }

    private var answerFieldBackground: Color {
        guard let result else { return Color.primaryText.opacity(0.06) }
        switch result {
        case .correct:   return Color.green.opacity(0.18)
        case .incorrect: return Color.red.opacity(0.16)
        }
    }

    private var answerFieldStroke: Color {
        guard result != nil else { return Color.primaryText.opacity(0.1) }
        return resultColor.opacity(0.54)
    }

    private var resultLabel: String {
        guard let result else { return " " }
        switch result {
        case .correct:
            return String(localized: "training.answer.correct")
        case .incorrect(let expected):
            return String.localizedStringWithFormat(String(localized: "training.answer.incorrect"), expected)
        }
    }

    private var resultColor: Color {
        guard let result else { return Color.primaryText.opacity(0.1) }
        switch result {
        case .correct:   return .green
        case .incorrect: return .red
        }
    }
}
