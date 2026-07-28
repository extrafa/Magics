import Foundation

@MainActor
protocol MindPatternSignalTransmitting {
    func transmit(_ animals: [MindPatternAnimal]) async
    func performerTapped()
    func cancel()
}

@MainActor
final class MindPatternSignalTransmitter: MindPatternSignalTransmitting {
    private let haptics: CountHapticPlaying
    private let gestureManager: PhoneTiltGestureManager
    private let preferences: MotionPreferenceManaging

    private let animalDelay: TimeInterval = 5
    private let firstSignalDelay: TimeInterval = 1
    // stored so performerTapped() can resume it from outside the async context
    private var performerTapContinuation: CheckedContinuation<Bool, Never>?

    init(
        haptics: CountHapticPlaying? = nil,
        preferences: MotionPreferenceManaging = AppPreferences.shared,
        gestureManager: PhoneTiltGestureManager? = nil
    ) {
        self.haptics = haptics ?? HapticManager.shared
        self.preferences = preferences
        self.gestureManager = gestureManager ?? PhoneTiltGestureManager(preferences: preferences)
    }

    func transmit(_ animals: [MindPatternAnimal]) async {
        let usesTrigger = preferences.isSecretGestureEnabled

        for (index, animal) in animals.enumerated() {
            if index > 0 {
                if usesTrigger {
                    guard await waitSeconds(animalDelay) else { return }
                    guard await gestureManager.waitForScreenDownGesture() else { return }
                } else {
                    guard await waitSeconds(animalDelay) else { return }
                }
            } else {
                if usesTrigger {
                    guard await gestureManager.waitForScreenDownGesture() else { return }
                } else {
                    guard await waitSeconds(firstSignalDelay) else { return }
                }
            }

            await playSignal(count: animal.signalCount)
        }
    }

    func performerTapped() {
        performerTapContinuation?.resume(returning: true)
        performerTapContinuation = nil
    }

    func cancel() {
        performerTapContinuation?.resume(returning: false)
        performerTapContinuation = nil
        gestureManager.stopMonitoring()
    }

    private func playSignal(count: Int) async {
        await withCheckedContinuation { continuation in
            haptics.playDigitSignal(count, initialDelay: HapticTiming.initialDelay) {
                continuation.resume()
            }
        }
    }

}
