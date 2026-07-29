//
//  HapticTrainingViewModel.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import Foundation

@MainActor
final class HapticTrainingViewModel: ObservableObject {

    enum GuessResult: Equatable {
        case correct
        case incorrect(expected: Int)
    }

    @Published private(set) var targetValue: Int
    @Published private(set) var result: GuessResult?
    @Published private(set) var correctCount = 0
    @Published private(set) var attemptCount = 0
    @Published private(set) var isPlaying = false
    @Published private(set) var hasPlayed = false

    private let mode: HapticTrainingMode
    private let options: [Int]
    private let countHaptics: CountHapticPlaying
    private let timeHaptics: TimeHapticPlaying

    init(
        mode: HapticTrainingMode = .digits,
        countHaptics: CountHapticPlaying? = nil,
        timeHaptics: TimeHapticPlaying? = nil
    ) {
        self.mode = mode
        self.options = Array(mode.range)
        self.targetValue = options.randomElement() ?? mode.range.lowerBound
        self.countHaptics = countHaptics ?? HapticManager.shared
        self.timeHaptics = timeHaptics ?? HapticManager.shared
    }

    func startNewRound() {
        targetValue = options.randomElement() ?? 0
        result = nil
        hasPlayed = false
        isPlaying = false
    }

    func submitGuess(_ value: Int) {
        attemptCount += 1

        if value == targetValue {
            correctCount += 1
            result = .correct
        } else {
            result = .incorrect(expected: targetValue)
        }
    }

    // Bridges the callback-based HapticManager API into async/await.
    func playSignal() async {
        guard !isPlaying else { return }
        isPlaying = true
        hasPlayed = true

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            switch mode.signalStyle {
            case .count:
                countHaptics.playTrainingDigit(targetValue) { continuation.resume() }
            case .timeValue:
                timeHaptics.playTimeValue(targetValue, initialDelay: 0, usesGrouping: true) { continuation.resume() }
            }
        }

        isPlaying = false
    }
}
