import CoreMotion
import Foundation

@MainActor
final class PhoneTiltGestureManager {

    private let motionManager = CMMotionManager()
    private let preferences: MotionPreferenceManaging
    private var monitoringTask: Task<Void, Never>?
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
            Task { @MainActor in completion(true) }
            return
        }

        pendingCompletion = completion
        screenDownSince = nil
        let holdDuration = preferences.screenDownHoldDuration

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
        guard pendingCompletion != nil else { return }

        let isScreenDown = gravityZ > 0.85

        if isScreenDown {
            if screenDownSince == nil { screenDownSince = Date() }
            if let since = screenDownSince, Date().timeIntervalSince(since) >= holdDuration {
                let handler = pendingCompletion
                stopMonitoring()
                handler?(true)
            }
        } else {
            screenDownSince = nil
        }
    }
}
