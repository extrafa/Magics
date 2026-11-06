import CoreMotion
import Foundation

@MainActor
final class PhoneTiltGestureManager {

    private let motionManager = CMMotionManager()
    private let motionQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInteractive
        return queue
    }()
    private let preferences: MotionPreferenceManaging
    private var pendingCompletion: (@MainActor (Bool) -> Void)?

    // MARK: Init

    init(preferences: MotionPreferenceManaging = AppPreferences.shared) {
        self.preferences = preferences
    }

    // MARK: Public

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
        motionManager.stopAccelerometerUpdates()
        resumePendingCompletion(with: false)
    }

    // MARK: Private

    private func resumePendingCompletion(with result: Bool) {
        let handler = pendingCompletion
        pendingCompletion = nil
        handler?(result)
    }

    private func startMonitoring(completion: @escaping @MainActor (Bool) -> Void) {
        resumePendingCompletion(with: false)

        guard motionManager.isAccelerometerAvailable else {
            // Simulator has no accelerometer; keep the gesture testable there.
            #if targetEnvironment(simulator)
            Task { @MainActor in completion(true) }
            #else
            Task { @MainActor in completion(false) }
            #endif
            return
        }

        pendingCompletion = completion
        let holdDuration = preferences.screenDownHoldDuration

        // Raw accelerometer at rest tracks gravity closely enough for a hold gesture, without the gyro+magnetometer fusion cost of device motion.
        var screenDownSince: Date?
        var didFire = false

        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: motionQueue) { [weak self] data, _ in
            guard let data, !didFire else { return }

            guard data.acceleration.z > 0.85 else {
                screenDownSince = nil
                return
            }

            let since = screenDownSince ?? Date()
            screenDownSince = since
            guard Date().timeIntervalSince(since) >= holdDuration else { return }

            didFire = true
            Task { @MainActor [weak self] in self?.handleGestureDetected() }
        }
    }

    private func handleGestureDetected() {
        let handler = pendingCompletion
        pendingCompletion = nil
        stopMonitoring()
        handler?(true)
    }
}
