import SwiftUI

struct HapticTrainingView: View {
    @StateObject private var viewModel: HapticTrainingViewModel
    @State private var answerText = ""
    @FocusState private var isAnswerFocused: Bool

    private let mode: HapticTrainingMode

    // Exact original Trickly color (TrickPalette.Collection.timeSuggestion)
    private let accentColor = Color.collectionTimeControl

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

    // MARK: - Signal deck

    private var signalDeck: some View {
        VStack(spacing: 18) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.16))
                        .frame(width: 92, height: 92)

                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(accentColor)
                }

                Text("Vibration Training")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(Color.primaryText)

                Text("Play a signal, then enter the number.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primaryText.opacity(0.54))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .frame(height: 22)
            }

            Button(action: playSignal) {
                Label("Play random number", systemImage: "dot.radiowaves.left.and.right")
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

    // MARK: - Answer section

    private var answerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Enter the number")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primaryText.opacity(viewModel.hasPlayed ? 0.58 : 0.28))

            ZStack {
                TextField("", text: $answerText)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(Color.primaryText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .focused($isAnswerFocused)
                    .disabled(!viewModel.hasPlayed || viewModel.result != nil)
                    .onChange(of: answerText) { _, newValue in
                        submitAnswerIfNeeded(from: newValue)
                    }

                if !isAnswerFocused && answerText.isEmpty {
                    Text("0-9")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(Color.primaryText.opacity(0.3))
                        .allowsHitTesting(false)
                }
            }
            .frame(height: 56)
            .background(answerFieldBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(answerFieldStroke, lineWidth: 1.2)
            }
            .opacity(viewModel.hasPlayed || viewModel.result != nil ? 1 : 0.42)

            Text(resultMessage)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(resultColor)
                .frame(maxWidth: .infinity, minHeight: 20, alignment: .center)
        }
    }

    private var answerFieldBackground: Color {
        guard let result = viewModel.result else { return Color.primaryText.opacity(0.06) }
        switch result {
        case .correct:   return Color.green.opacity(0.18)
        case .incorrect: return Color.red.opacity(0.16)
        }
    }

    private var answerFieldStroke: Color {
        guard viewModel.result != nil else { return Color.primaryText.opacity(0.1) }
        return resultColor.opacity(0.54)
    }

    private var resultMessage: String {
        guard let result = viewModel.result else { return " " }
        switch result {
        case .correct:
            return String(localized: "training.answer.correct")
        case .incorrect(let expected):
            return String.localizedStringWithFormat(String(localized: "training.answer.incorrect"), expected)
        }
    }

    private var resultColor: Color {
        guard let result = viewModel.result else { return Color.primaryText.opacity(0.1) }
        switch result {
        case .correct:   return .green
        case .incorrect: return .red
        }
    }

    // MARK: - Actions

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
                try? await Task.sleep(nanoseconds: 250_000_000)
            }
            isAnswerFocused = viewModel.result == nil
        }
    }

    private func submitAnswerIfNeeded(from value: String) {
        let maxDigits = mode.usesExplicitSubmit ? 2 : 1
        let filtered = String(value.filter(\.isNumber).prefix(maxDigits))
        if answerText != filtered {
            answerText = filtered
            return
        }
        guard viewModel.hasPlayed, viewModel.result == nil else { return }
        if !mode.usesExplicitSubmit, let number = Int(filtered) {
            viewModel.submitGuess(number)
        }
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
