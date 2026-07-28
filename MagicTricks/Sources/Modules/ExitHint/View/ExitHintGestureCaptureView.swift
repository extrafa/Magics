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
        private var tapRecognizer: UITapGestureRecognizer?
        private var didTriggerExit = false

        init(onExit: @escaping () -> Void) {
            self.onExit = onExit
        }

        func installRecognizerIfNeeded(on window: UIWindow) {
            guard installedWindow !== window else { return }

            if let longPressRecognizer, let installedWindow {
                installedWindow.removeGestureRecognizer(longPressRecognizer)
            }

            if let tapRecognizer, let installedWindow {
                installedWindow.removeGestureRecognizer(tapRecognizer)
            }

            let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            longPressRecognizer.minimumPressDuration = ExitHintZone.minimumPressDuration
            longPressRecognizer.cancelsTouchesInView = false
            longPressRecognizer.delegate = self
            window.addGestureRecognizer(longPressRecognizer)

            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            tapRecognizer.cancelsTouchesInView = false
            tapRecognizer.delaysTouchesBegan = false
            tapRecognizer.delaysTouchesEnded = false
            tapRecognizer.delegate = self
            window.addGestureRecognizer(tapRecognizer)

            installedWindow = window
            self.longPressRecognizer = longPressRecognizer
            self.tapRecognizer = tapRecognizer
        }

        @objc private func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
            switch recognizer.state {
            case .began:
                let location = recognizer.location(in: recognizer.view)
                let targetRect = ExitHintGestureState.shared.globalRect
                guard targetRect.contains(location), !didTriggerExit else { return }
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
            let targetRect = ExitHintGestureState.shared.globalRect
            guard !targetRect.contains(location) else { return }
            ExitHintGestureState.shared.onOutsideTap?()
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            if gestureRecognizer === tapRecognizer {
                return ExitHintGestureState.shared.isTrainingActive
            }

            return true
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }
    }
}

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
        if let window {
            onMoveToWindow?(window)
        }
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
