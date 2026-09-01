//
//  ExitHintGestureCaptureView.swift
//  Magic Tricks
//
//  Created by Ross on 09/04/2026.
//

import SwiftUI
import UIKit

private struct ExitHintLongPressModifier: ViewModifier {
    let onExit: () -> Void

    func body(content: Content) -> some View {
        content.overlay {
            ExitHintGestureCaptureView(onExit: onExit)
        }
    }
}

private struct ExitHintGestureCaptureView: UIViewRepresentable {
    let onExit: () -> Void

    @EnvironmentObject private var gestureCoordinator: ExitHintGestureCoordinator

    func makeCoordinator() -> Coordinator {
        Coordinator(onExit: onExit)
    }

    func makeUIView(context: Context) -> GestureInstallerView {
        let view = GestureInstallerView()
        context.coordinator.installerView = view
        view.onMoveToWindow = { window in
            context.coordinator.installRecognizerIfNeeded(on: window)
        }
        return view
    }

    func updateUIView(_ uiView: GestureInstallerView, context: Context) {
        context.coordinator.onExit = onExit
        context.coordinator.gestureCoordinator = gestureCoordinator
        uiView.isTrainingActive = gestureCoordinator.isTrainingActive
        if let window = uiView.window {
            context.coordinator.installRecognizerIfNeeded(on: window)
        }
    }

    static func dismantleUIView(_ uiView: GestureInstallerView, coordinator: Coordinator) {
        coordinator.teardown()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onExit: () -> Void
        weak var installerView: UIView?
        weak var gestureCoordinator: ExitHintGestureCoordinator?
        private weak var installedWindow: UIWindow?
        private var longPressRecognizer: UILongPressGestureRecognizer?
        private var touchTracker: TouchTrackingRecognizer?
        private var tapRecognizer: UITapGestureRecognizer?
        private var panRecognizer: UIPanGestureRecognizer?
        private var didTriggerExit = false
        private var isHoldActive = false
        private var panStartedInRect = false
        private var didTriggerSwipe = false
        private var touchStartTime: Date?

        init(onExit: @escaping () -> Void) {
            self.onExit = onExit
        }

        // The hint zone is drawn at a fixed offset/size within the capture view's
        // own bounds (see ExitHintView.body), so its screen rect is derived from
        // UIKit layout directly instead of round-tripping through SwiftUI's
        // GeometryReader/.global coordinate space, which reported stale values here.
        private var rect: CGRect {
            guard let installerView, let window = installerView.window else { return .zero }
            let localRect = CGRect(
                x: ExitHintZone.leadingInset,
                y: ExitHintZone.topInset,
                width: ExitHintZone.frame.width,
                height: ExitHintZone.frame.height
            )
            return installerView.convert(localRect, to: window)
        }

        func installRecognizerIfNeeded(on window: UIWindow) {
            guard installedWindow !== window else { return }
            removeInstalledRecognizers()

            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            longPress.minimumPressDuration = ExitHintZone.minimumPressDuration
            longPress.allowableMovement = ExitHintZone.longPressAllowableMovement
            longPress.cancelsTouchesInView = false
            longPress.delegate = self
            window.addGestureRecognizer(longPress)

            let tracker = TouchTrackingRecognizer()
            tracker.cancelsTouchesInView = false
            tracker.delegate = self

            tracker.onTouchDown = { [weak self] location in
                guard let self else { return }
                guard self.rect.contains(location) else { return }
                self.isHoldActive = true
                self.touchStartTime = Date()
                self.gestureCoordinator?.onHoldStarted?()
            }

            tracker.onTouchMoved = { [weak self] location in
                guard let self, self.isHoldActive else { return }
                let activeRect = self.rect.insetBy(dx: -ExitHintZone.hitTestMargin, dy: -ExitHintZone.hitTestMargin)
                if !activeRect.contains(location) {
                    self.isHoldActive = false
                    self.gestureCoordinator?.onHoldCancelled?()
                }
            }

            tracker.onTouchUp = { [weak self] in
                guard let self, self.isHoldActive else { return }
                self.isHoldActive = false
                self.gestureCoordinator?.onHoldCancelled?()
            }

            window.addGestureRecognizer(tracker)

            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            tap.cancelsTouchesInView = false
            tap.delaysTouchesBegan = false
            tap.delaysTouchesEnded = false
            tap.delegate = self
            window.addGestureRecognizer(tap)

            let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            pan.minimumNumberOfTouches = 1
            pan.maximumNumberOfTouches = 1
            pan.cancelsTouchesInView = false
            pan.delegate = self
            window.addGestureRecognizer(pan)

            installedWindow = window
            longPressRecognizer = longPress
            touchTracker = tracker
            tapRecognizer = tap
            panRecognizer = pan
        }

        func teardown() {
            removeInstalledRecognizers()
            installedWindow = nil
            longPressRecognizer = nil
            touchTracker = nil
            tapRecognizer = nil
            panRecognizer = nil
        }

        private func removeInstalledRecognizers() {
            guard let window = installedWindow else { return }
            [longPressRecognizer, touchTracker, tapRecognizer, panRecognizer].forEach { recognizer in
                if let recognizer { window.removeGestureRecognizer(recognizer) }
            }
        }

        @objc private func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
            switch recognizer.state {
            case .began:
                let location = recognizer.location(in: recognizer.view)
                let expandedRect = rect.insetBy(dx: -ExitHintZone.hitTestMargin, dy: -ExitHintZone.hitTestMargin)
                guard expandedRect.contains(location), !didTriggerExit, !didTriggerSwipe else {
                    return
                }
                didTriggerExit = true
                if gestureCoordinator?.isTrainingActive == true {
                    gestureCoordinator?.onTrainingHold?()
                } else {
                    onExit()
                }
            case .ended, .cancelled, .failed:
                didTriggerExit = false
            default:
                break
            }
        }

        @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
            switch recognizer.state {
            case .began:
                let location = recognizer.location(in: recognizer.view)
                let translation = recognizer.translation(in: recognizer.view)
                let startLocation = CGPoint(
                    x: location.x - translation.x,
                    y: location.y - translation.y
                )
                panStartedInRect = rect.contains(startLocation)
                didTriggerSwipe = false
            case .changed:
                guard panStartedInRect, !didTriggerSwipe, !didTriggerExit,
                      gestureCoordinator?.isTrainingActive == true else { return }
                if let start = touchStartTime, Date().timeIntervalSince(start) > ExitHintSwipeGesture.timeLimit { return }
                let velocity = recognizer.velocity(in: recognizer.view)
                let speed = hypot(velocity.x, velocity.y)
                guard speed > ExitHintSwipeGesture.minimumSpeed else { return }
                didTriggerSwipe = true
                gestureCoordinator?.onSwipe?()
            case .ended, .cancelled, .failed:
                panStartedInRect = false
                didTriggerSwipe = false
            default:
                break
            }
        }

        @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard recognizer.state == .ended, gestureCoordinator?.isTrainingActive == true else { return }
            let location = recognizer.location(in: recognizer.view)
            guard !rect.contains(location) else { return }
            gestureCoordinator?.onOutsideTap?()
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            if gestureRecognizer === tapRecognizer {
                return gestureCoordinator?.isTrainingActive == true
            }
            return true
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
        ) -> Bool { true }
    }
}

// MARK: - Touch tracking

private final class TouchTrackingRecognizer: UIGestureRecognizer {
    var onTouchDown: ((CGPoint) -> Void)?
    var onTouchMoved: ((CGPoint) -> Void)?
    var onTouchUp: (() -> Void)?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else { return }
        onTouchDown?(touch.location(in: view))
        state = .began
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        guard let touch = touches.first else { return }
        onTouchMoved?(touch.location(in: view))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        onTouchUp?()
        state = .ended
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        onTouchUp?()
        state = .cancelled
    }
}

// MARK: - Installer view

private final class GestureInstallerView: UIView {
    var onMoveToWindow: ((UIWindow) -> Void)?
    var isTrainingActive = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if let window { onMoveToWindow?(window) }
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        isTrainingActive
    }
}

extension View {
    func exitHintLongPressEnabled(onExit: @escaping () -> Void) -> some View {
        modifier(ExitHintLongPressModifier(onExit: onExit))
    }
}
