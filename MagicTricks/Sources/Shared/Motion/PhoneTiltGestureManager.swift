import CoreMotion
import Foundation

/// Detects when the phone is held screen-face-down and held steady for the
/// required duration (`screenDownHoldDuration` from preferences).
@MainActor
final class PhoneTiltGestureManager {

    private let motionManager = CMMotionManager()
    private let preferences: MotionPreferenceManaging
    private var monitoringTask: Task<Void, Never>?

    // MARK: Init

    init(preferences: MotionPreferenceManaging = AppPreferences.shared) {
        self.preferences = preferences
    }

    convenience init() {
        self.init(preferences: AppPreferences.shared)
    }

    // MARK: Public

    /// Suspends until the user holds the phone screen-down for the configured
    /// duration, then returns `true`. Returns `false` if monitoring is
    /// cancelled before the gesture is detected.
    func waitForScreenDownGesture() async -> Bool {
        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                startMonitoring { detected in
                    continuation.resume(returning: detected)
                }
            }
        } onCancel: {
            Task { @MainActor in self.stopMonitoring() }
        }
    }

    func stopMonitoring() {
        motionManager.stopDeviceMotionUpdates()
        monitoringTask?.cancel()
        monitoringTask = nil
    }

    // MARK: Private

    private func startMonitoring(completion: @escaping @MainActor (Bool) -> Void) {
        guard motionManager.isDeviceMotionAvailable else {
            // Motion unavailable — treat as if gesture fired immediately
            Task { @MainActor in completion(true) }
            return
        }

        let holdDuration = preferences.screenDownHoldDuration
        var screenDownSince: Date?

        motionManager.deviceMotionUpdateInterval = 0.05
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }

            // Gravity.z < -0.85 means the screen is facing roughly downward
            let isScreenDown = motion.gravity.z < -0.85

            if isScreenDown {
                if screenDownSince == nil { screenDownSince = Date() }
                if let since = screenDownSince, Date().timeIntervalSince(since) >= holdDuration {
                    self.stopMonitoring()
                    completion(true)
                }
            } else {
                screenDownSince = nil
            }
        }
    }
}
