import CoreMotion
import Foundation

/// Detects when the phone is held screen-face-down and held steady for the
/// required duration (`screenDownHoldDuration` from preferences).
@MainActor
final class PhoneTiltGestureManager {

    private let motionManager = CMMotionManager()
    private let preferences: MotionPreferenceManaging
    private var monitoringTask: Task<Void, Never>?

    // Stored on the actor so the CoreMotion callback (background queue)
    // can safely write via Task { @MainActor }.
    private var screenDownSince: Date?
    private var pendingCompletion: (@MainActor (Bool) -> Void)?

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
        screenDownSince = nil
        pendingCompletion = nil
    }

    // MARK: Private

    private func startMonitoring(completion: @escaping @MainActor (Bool) -> Void) {
        guard motionManager.isDeviceMotionAvailable else {
            // Motion unavailable — treat as if gesture fired immediately
            Task { @MainActor in completion(true) }
            return
        }

        pendingCompletion = completion
        screenDownSince = nil
        let holdDuration = preferences.screenDownHoldDuration

        // Use a dedicated background queue. OperationQueue.main is NOT the
        // Swift @MainActor executor in iOS 18+, so accessing @MainActor-isolated
        // state from a .main callback causes an actor isolation violation.
        // Instead, use a background queue and hop back to @MainActor explicitly.
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInteractive

        motionManager.deviceMotionUpdateInterval = 0.05
        motionManager.startDeviceMotionUpdates(to: queue) { [weak self] motion, _ in
            guard let motion else { return }
            let gravityZ = motion.gravity.z
            Task { @MainActor [weak self] in
                self?.handleMotionUpdate(gravityZ: gravityZ, holdDuration: holdDuration)
            }
        }
    }

    private func handleMotionUpdate(gravityZ: Double, holdDuration: TimeInterval) {
        // Guard early if stopMonitoring was already called
        guard pendingCompletion != nil else { return }

        // Device z-axis points out of the screen toward the user.
        // Face up  → z-axis points to ceiling, gravity is -z → gravity.z ≈ -1
        // Face down → z-axis points to floor,   gravity is +z → gravity.z ≈ +1
        let isScreenDown = gravityZ > 0.85

        if isScreenDown {
            if screenDownSince == nil { screenDownSince = Date() }
            if let since = screenDownSince, Date().timeIntervalSince(since) >= holdDuration {
                // Capture before stopMonitoring nils it
                let handler = pendingCompletion
                stopMonitoring()
                handler?(true)
            }
        } else {
            screenDownSince = nil
        }
    }
}
