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

    func makeCoordinator() -> Coordinator {
        Coordinator(onExit: onExit)
    }

    func makeUIView(context: Context) -> GestureInstallerView {
        let view = GestureInstallerView()
        view.onMoveToWindow = { window in
            context.coordinator.installRecognizerIfNeeded(on: window)
        }
        return view
    }

    func updateUIView(_ uiView: GestureInstallerView, context: Context) {
        context.coordinator.onExit = onExit
        if let window = uiView.window {
            context.coordinator.installRecognizerIfNeeded(on: window)
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onExit: () -> Void
        private weak var installedWindow: UIWindow?
        private var longPressRecognizer: UILongPressGestureRecognizer?
        private var touchTracker: TouchTrackingRecognizer?
        private var tapRecognizer: UITapGestureRecognizer?
        private var didTriggerExit = false
        private var isHoldActive = false

        init(onExit: @escaping () -> Void) {
            self.onExit = onExit
        }

        func installRecognizerIfNeeded(on window: UIWindow) {
            guard installedWindow !== window else { return }

            [longPressRecognizer, touchTracker, tapRecognizer].forEach { recognizer in
                if let r = recognizer, let w = installedWindow {
                    w.removeGestureRecognizer(r)
                }
            }

            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            longPress.minimumPressDuration = ExitHintZone.minimumPressDuration
            longPress.allowableMovement = 1000
            longPress.cancelsTouchesInView = false
            longPress.delegate = self
            window.addGestureRecognizer(longPress)

            let tracker = TouchTrackingRecognizer()
            tracker.cancelsTouchesInView = false
            tracker.delegate = self

            tracker.onTouchDown = { [weak self] location in
                guard let self else { return }
                guard ExitHintGestureState.shared.globalRect.contains(location) else { return }
                self.isHoldActive = true
                ExitHintGestureState.shared.onHoldStarted?()
            }

            tracker.onTouchMoved = { [weak self] location in
                guard let self, self.isHoldActive else { return }
                let activeRect = ExitHintGestureState.shared.globalRect.insetBy(dx: -20, dy: -20)
                if !activeRect.contains(location) {
                    self.isHoldActive = false
                    ExitHintGestureState.shared.onHoldCancelled?()
                }
            }

            tracker.onTouchUp = { [weak self] in
                guard let self, self.isHoldActive else { return }
                self.isHoldActive = false
                ExitHintGestureState.shared.onHoldCancelled?()
            }

            window.addGestureRecognizer(tracker)

            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            tap.cancelsTouchesInView = false
            tap.delaysTouchesBegan = false
            tap.delaysTouchesEnded = false
            tap.delegate = self
            window.addGestureRecognizer(tap)

            installedWindow = window
            longPressRecognizer = longPress
            touchTracker = tracker
            tapRecognizer = tap
        }

        @objc private func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
            switch recognizer.state {
            case .began:
                let location = recognizer.location(in: recognizer.view)
                let expandedRect = ExitHintGestureState.shared.globalRect.insetBy(dx: -20, dy: -20)
                guard expandedRect.contains(location), !didTriggerExit else {
                    return
                }
                didTriggerExit = true
                if ExitHintGestureState.shared.isTrainingActive {
                    ExitHintGestureState.shared.onTrainingHold?()
                } else {
                    onExit()
                }
            case .ended, .cancelled, .failed:
                didTriggerExit = false
            default:
                break
            }
        }

        @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard recognizer.state == .ended, ExitHintGestureState.shared.isTrainingActive else { return }
            let location = recognizer.location(in: recognizer.view)
            guard !ExitHintGestureState.shared.globalRect.contains(location) else { return }
            ExitHintGestureState.shared.onOutsideTap?()
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            if gestureRecognizer === tapRecognizer {
                return ExitHintGestureState.shared.isTrainingActive
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
        ExitHintGestureState.shared.isTrainingActive
    }
}

extension View {
    func exitHintLongPressEnabled(onExit: @escaping () -> Void) -> some View {
        modifier(ExitHintLongPressModifier(onExit: onExit))
    }
}
