import CoreMotion
import Foundation

enum ScreenDownResult: Equatable {
    case detected
    case timedOut
    case cancelled
}

@MainActor
final class PhoneTiltGestureManager {

    // A phone lying on a table reads 1.0; a hand never holds it perfectly level, so a little tilt still counts.
    private static let faceDownThreshold = 0.8

    private let motionManager: CMMotionManager
    private let motionQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInteractive
        return queue
    }()
    private let preferences: MotionPreferenceManaging
    private var pendingCompletion: (@MainActor (Bool) -> Void)?
    // Which wait owns the sensor now: a late cancel of an old wait must not stop a newer one.
    private var activeToken: UUID?

    // MARK: Init

    init(
        preferences: MotionPreferenceManaging = AppPreferences.shared,
        motionManager: CMMotionManager = CMMotionManager()
    ) {
        self.preferences = preferences
        self.motionManager = motionManager
    }

    // MARK: Public

    func waitForScreenDownGesture() async -> Bool {
        let token = UUID()
        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                // Already cancelled: starting now would leave the sensor running with nobody waiting.
                guard !Task.isCancelled else {
                    continuation.resume(returning: false)
                    return
                }
                startMonitoring(token: token) { detected in
                    continuation.resume(returning: detected)
                }
            }
        } onCancel: {
            Task { @MainActor in self.stopMonitoring(ifOwnedBy: token) }
        }
    }

    // The same wait, but it gives up after `timeout` seconds.
    func waitForScreenDownGesture(timeout: TimeInterval) async -> ScreenDownResult {
        await withTaskGroup(of: ScreenDownResult.self) { group in
            group.addTask { await self.waitForScreenDownGesture() ? .detected : .cancelled }
            group.addTask {
                try? await Task.sleep(seconds: timeout)
                return .timedOut
            }
            let first = await group.next() ?? .cancelled
            group.cancelAll()
            return Task.isCancelled ? .cancelled : first
        }
    }

    func stopMonitoring() {
        activeToken = nil
        motionManager.stopAccelerometerUpdates()
        resumePendingCompletion(with: false)
    }

    // MARK: Private

    private func stopMonitoring(ifOwnedBy token: UUID) {
        guard activeToken == token else { return }
        stopMonitoring()
    }

    private func resumePendingCompletion(with result: Bool) {
        let handler = pendingCompletion
        pendingCompletion = nil
        handler?(result)
    }

    private func startMonitoring(token: UUID, completion: @escaping @MainActor (Bool) -> Void) {
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

        activeToken = token
        pendingCompletion = completion
        let holdDuration = preferences.screenDownHoldDuration
        let threshold = Self.faceDownThreshold

        // Raw accelerometer at rest tracks gravity closely enough for a hold gesture, without the gyro+magnetometer fusion cost of device motion.
        var screenDownSince: Date?
        var didFire = false

        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: motionQueue) { [weak self] data, _ in
            guard let data, !didFire else { return }

            guard data.acceleration.z > threshold else {
                screenDownSince = nil
                return
            }

            let since = screenDownSince ?? Date()
            screenDownSince = since
            guard Date().timeIntervalSince(since) >= holdDuration else { return }

            didFire = true
            Task { @MainActor [weak self] in self?.handleGestureDetected(ifOwnedBy: token) }
        }
    }

    private func handleGestureDetected(ifOwnedBy token: UUID) {
        // A hit that was already on its way when this wait ended must not complete a newer one.
        guard activeToken == token else { return }
        let handler = pendingCompletion
        pendingCompletion = nil
        stopMonitoring()
        handler?(true)
    }
}
