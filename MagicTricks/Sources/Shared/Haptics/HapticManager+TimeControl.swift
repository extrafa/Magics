import Foundation

extension HapticManager {
    func playGroupedTimeValue(_ value: Int, initialDelay: TimeInterval = HapticTiming.initialDelay, completion: (() -> Void)? = nil) {
        let tens = value / 10
        let ones = value % 10
        let gapAfterTens = HapticPreferences.groupedDigitGap

        playGroupedCountSignal(tens, initialDelay: initialDelay, generator: heavyImpactGenerator) {
            self.schedule(after: gapAfterTens) {
                self.playGroupedCountSignal(ones, generator: self.heavyImpactGenerator, completion: completion)
            }
        }
    }

    func playClassicTimeValue(_ value: Int, initialDelay: TimeInterval, completion: (() -> Void)?) {
        let tens = value / 10
        let ones = value % 10
        let totalDuration = TimeControlHapticPattern.digitDuration(tens)
        + TimeControlHapticPattern.digitGap
        + TimeControlHapticPattern.digitDuration(ones)

        playTimeValueWithCoreHaptics(tens: tens, ones: ones, initialDelay: initialDelay)
        scheduleCompletion(
            initialDelay: initialDelay,
            signalDuration: totalDuration,
            completion: completion
        )
    }

    func playTimeValueWithCoreHaptics(tens: Int, ones: Int, initialDelay: TimeInterval) {
        let events = TimeHapticPatternBuilder.timeValueEvents(
            tens: tens,
            ones: ones,
            initialDelay: initialDelay
        )

        playCoreHapticEvents(events) {
            playTimeValueFallback(tens: tens, ones: ones, initialDelay: initialDelay)
        }
    }

    func playTimeValueFallback(tens: Int, ones: Int, initialDelay: TimeInterval) {
        heavyImpactGenerator.prepare()
        var time = initialDelay

        time = scheduler.scheduleTimeDigit(tens, startTime: time, generator: heavyImpactGenerator)
        time += TimeControlHapticPattern.digitGap
        _ = scheduler.scheduleTimeDigit(ones, startTime: time, generator: heavyImpactGenerator)
    }
}
