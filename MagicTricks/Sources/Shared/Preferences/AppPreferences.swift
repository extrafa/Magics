import Foundation

protocol PreferenceStoring {
    func object(forKey defaultName: String) -> Any?
    func bool(forKey defaultName: String) -> Bool
    func double(forKey defaultName: String) -> Double
    func stringArray(forKey defaultName: String) -> [String]?
    func set(_ value: Any?, forKey defaultName: String)
}

extension UserDefaults: PreferenceStoring {}

protocol ExitHintPreferenceManaging {
    var didLearnExitHint: Bool { get set }
}

protocol HapticPreferenceManaging {
    var hapticSpeedMultiplier: Double { get set }
    var isHapticGroupByThreeEnabled: Bool { get set }

    func resetHapticSettings()
}

protocol MotionPreferenceManaging {
    var isSecretGestureEnabled: Bool { get set }
    var screenDownHoldDuration: TimeInterval { get set }

    func resetMotionSettings()
}

protocol MagicGalleryPreferenceManaging {
    var usesStandardMagicGallerySet: Bool { get set }
    var magicGalleryGestureMode: MagicGalleryGestureMode { get set }
}

struct AppPreferences: ExitHintPreferenceManaging, HapticPreferenceManaging, MotionPreferenceManaging, MagicGalleryPreferenceManaging {
    static let shared = AppPreferences()

    private let store: PreferenceStoring

    init(store: PreferenceStoring = UserDefaults.standard) {
        self.store = store
    }

    enum Key {
        static let hapticSpeedMultiplier = "hapticSpeedMultiplier"
        static let hapticGroupByThreeEnabled = "hapticGroupByThreeEnabled"
        static let hapticIntensity = "hapticIntensity"
        static let secretGestureEnabled = "secretGestureEnabled"
        static let screenDownHoldDuration = "screenDownHoldDuration"
        static let didLearnExitHint = "didLearnExitHint"
        static let isExitHintEnabled = "isExitHintEnabled"
        static let usesStandardMagicGallerySet = "ImpossibleGalleryUsesStandardSet"
        static let magicGalleryGestureMode = "magicGalleryGestureMode"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let trickLaunchCount = "trickLaunchCount"
        static let hasRespondedToRating = "hasRespondedToRating"
        static let seenTrickIds = "seenTrickIds"
    }

    enum Default {
        static let hapticSpeedMultiplier = 1.5
        static let hapticGroupByThreeEnabled = false
        static let hapticIntensity = HapticIntensity.heavy
        static let secretGestureEnabled = false
        static let screenDownHoldDuration = 0.30
        static let isExitHintEnabled = true
        static let usesStandardMagicGallerySet = true
    }

    enum Range {
        static let hapticSpeedMultiplier = 1.0...2.5
        static let screenDownHoldDuration = 0.10...1.50
    }

    var hapticSpeedMultiplier: Double {
        get {
            clampedDouble(
                forKey: Key.hapticSpeedMultiplier,
                defaultValue: Default.hapticSpeedMultiplier,
                range: Range.hapticSpeedMultiplier
            )
        }
        nonmutating set {
            store.set(
                clamped(newValue, range: Range.hapticSpeedMultiplier),
                forKey: Key.hapticSpeedMultiplier
            )
        }
    }

    var isHapticGroupByThreeEnabled: Bool {
        get { store.bool(forKey: Key.hapticGroupByThreeEnabled) }
        nonmutating set { store.set(newValue, forKey: Key.hapticGroupByThreeEnabled) }
    }

    var hapticIntensity: HapticIntensity {
        get {
            guard store.object(forKey: Key.hapticIntensity) != nil else {
                return Default.hapticIntensity
            }
            switch Int(store.double(forKey: Key.hapticIntensity)) {
            case 0: return .light
            case 2: return .heavy
            default: return .medium
            }
        }
        nonmutating set {
            let raw: Double
            switch newValue {
            case .light: raw = 0
            case .medium: raw = 1
            case .heavy: raw = 2
            }
            store.set(raw, forKey: Key.hapticIntensity)
        }
    }

    var isSecretGestureEnabled: Bool {
        get { store.bool(forKey: Key.secretGestureEnabled) }
        nonmutating set { store.set(newValue, forKey: Key.secretGestureEnabled) }
    }

    var screenDownHoldDuration: TimeInterval {
        get {
            clampedDouble(
                forKey: Key.screenDownHoldDuration,
                defaultValue: Default.screenDownHoldDuration,
                range: Range.screenDownHoldDuration
            )
        }
        nonmutating set {
            store.set(
                clamped(newValue, range: Range.screenDownHoldDuration),
                forKey: Key.screenDownHoldDuration
            )
        }
    }

    var didLearnExitHint: Bool {
        get { store.bool(forKey: Key.didLearnExitHint) }
        nonmutating set { store.set(newValue, forKey: Key.didLearnExitHint) }
    }

    var isExitHintEnabled: Bool {
        get {
            guard store.object(forKey: Key.isExitHintEnabled) != nil else {
                return Default.isExitHintEnabled
            }
            return store.bool(forKey: Key.isExitHintEnabled)
        }
        nonmutating set { store.set(newValue, forKey: Key.isExitHintEnabled) }
    }

    var hasCompletedOnboarding: Bool {
        get { store.bool(forKey: Key.hasCompletedOnboarding) }
        nonmutating set { store.set(newValue, forKey: Key.hasCompletedOnboarding) }
    }

    var trickLaunchCount: Int {
        get { Int(store.double(forKey: Key.trickLaunchCount)) }
        nonmutating set { store.set(Double(newValue), forKey: Key.trickLaunchCount) }
    }

    var hasRespondedToRating: Bool {
        get { store.bool(forKey: Key.hasRespondedToRating) }
        nonmutating set { store.set(newValue, forKey: Key.hasRespondedToRating) }
    }

    var seenTrickIds: [String] {
        get { store.stringArray(forKey: Key.seenTrickIds) ?? [] }
        nonmutating set { store.set(newValue, forKey: Key.seenTrickIds) }
    }

    var usesStandardMagicGallerySet: Bool {
        get {
            guard store.object(forKey: Key.usesStandardMagicGallerySet) != nil else {
                return Default.usesStandardMagicGallerySet
            }
            return store.bool(forKey: Key.usesStandardMagicGallerySet)
        }
        nonmutating set { store.set(newValue, forKey: Key.usesStandardMagicGallerySet) }
    }

    var magicGalleryGestureMode: MagicGalleryGestureMode {
        get {
            guard store.object(forKey: Key.magicGalleryGestureMode) != nil else { return .tap }
            return MagicGalleryGestureMode(rawValue: Int(store.double(forKey: Key.magicGalleryGestureMode))) ?? .tap
        }
        nonmutating set { store.set(Double(newValue.rawValue), forKey: Key.magicGalleryGestureMode) }
    }

    func resetHapticSettings() {
        store.set(Default.hapticSpeedMultiplier, forKey: Key.hapticSpeedMultiplier)
        store.set(Default.hapticGroupByThreeEnabled, forKey: Key.hapticGroupByThreeEnabled)
        store.set(2.0, forKey: Key.hapticIntensity)
    }

    func resetMotionSettings() {
        store.set(Default.secretGestureEnabled, forKey: Key.secretGestureEnabled)
        store.set(Default.screenDownHoldDuration, forKey: Key.screenDownHoldDuration)
        store.set(Default.isExitHintEnabled, forKey: Key.isExitHintEnabled)
    }

    private func clampedDouble(
        forKey key: String,
        defaultValue: Double,
        range: ClosedRange<Double>
    ) -> Double {
        guard store.object(forKey: key) != nil else { return defaultValue }
        return clamped(store.double(forKey: key), range: range)
    }

    private func clamped(_ value: Double, range: ClosedRange<Double>) -> Double {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
