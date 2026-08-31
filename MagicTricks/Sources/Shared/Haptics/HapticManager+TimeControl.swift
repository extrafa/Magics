//
//  HapticManager+TimeControl.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import Foundation

extension HapticManager {
    func playGroupedTimeValue(_ value: Int, initialDelay: TimeInterval = HapticTiming.initialDelay, timings: HapticTimings, completion: Completion? = nil) {
        let tens = value / 10
        let ones = value % 10
        let gapAfterTens = timings.grouped.digitGap

        playGroupedCountSignal(tens, initialDelay: initialDelay, generator: impactGenerator, timings: timings) {
            self.schedule(after: gapAfterTens) {
                self.playGroupedCountSignal(ones, generator: self.impactGenerator, timings: timings, completion: completion)
            }
        }
    }

    func playClassicTimeValue(_ value: Int, initialDelay: TimeInterval, timings: HapticTimings, completion: Completion?) {
        let tens = value / 10
        let ones = value % 10
        let totalDuration = timings.digitDuration(tens)
            + timings.digitGap
            + timings.digitDuration(ones)

        playTimeValueWithCoreHaptics(tens: tens, ones: ones, initialDelay: initialDelay, timings: timings)
        scheduleCompletion(
            initialDelay: initialDelay,
            signalDuration: totalDuration,
            completion: completion
        )
    }

    func playTimeValueWithCoreHaptics(tens: Int, ones: Int, initialDelay: TimeInterval, timings: HapticTimings) {
        let events = TimeHapticPatternBuilder.timeValueEvents(
            tens: tens,
            ones: ones,
            initialDelay: initialDelay,
            timings: timings
        )

        playCoreHapticEvents(events) {
            playTimeValueFallback(tens: tens, ones: ones, initialDelay: initialDelay, timings: timings)
        }
    }

    func playTimeValueFallback(tens: Int, ones: Int, initialDelay: TimeInterval, timings: HapticTimings) {
        impactGenerator.prepare()
        var time = initialDelay

        time = scheduler.scheduleTimeDigit(tens, startTime: time, generator: impactGenerator)
        time += timings.digitGap
        _ = scheduler.scheduleTimeDigit(ones, startTime: time, generator: impactGenerator)
    }
}
