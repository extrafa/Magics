//
//  TestDoubles.swift
//  MagicTricksTests
//

import Foundation
@testable import MagicTricks

// In-memory stand-in for UserDefaults, shared by every test that needs a PreferenceStoring.
final class MockPreferenceStore: PreferenceStoring {
    var storage: [String: Any] = [:]

    func object(forKey defaultName: String) -> Any? { storage[defaultName] }
    func bool(forKey defaultName: String) -> Bool { (storage[defaultName] as? Bool) ?? false }
    func double(forKey defaultName: String) -> Double { (storage[defaultName] as? Double) ?? 0 }
    func integer(forKey defaultName: String) -> Int {
        // Like UserDefaults: a number stored as Double still reads back as an Int.
        if let value = storage[defaultName] as? Int { return value }
        return (storage[defaultName] as? Double).map(Int.init) ?? 0
    }
    func stringArray(forKey defaultName: String) -> [String]? { storage[defaultName] as? [String] }
    func set(_ value: Any?, forKey defaultName: String) { storage[defaultName] = value }
}

struct MockHapticPreferences: HapticPreferenceManaging {
    var hapticSpeedMultiplier: Double
    var isHapticGroupByThreeEnabled: Bool
    var hapticIntensity: HapticIntensity

    init(speed: Double = 1.0, groupByThree: Bool = false, intensity: HapticIntensity = .heavy) {
        hapticSpeedMultiplier = speed
        isHapticGroupByThreeEnabled = groupByThree
        hapticIntensity = intensity
    }

    func resetHapticSettings() {}
}

// Records the counts a trick asked to vibrate and lets a test decide when the signal "ends".
@MainActor
final class MockCountHaptics: CountHapticPlaying {
    private(set) var playedCounts: [Int] = []
    private(set) var cancelCount = 0
    private var completion: Completion?

    func playCount(_ count: Int, completion: Completion?) {
        playedCounts.append(count)
        self.completion = completion
    }

    func cancelPendingHaptics() {
        cancelCount += 1
    }

    func finishPlaying() {
        let finish = completion
        completion = nil
        finish?()
    }
}
