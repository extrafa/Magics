//
//  MagicGalleryCameraView.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import SwiftUI
import UIKit

struct MagicGalleryCameraView: View {
    let number: Int
    let sourceType: UIImagePickerController.SourceType
    let onCaptured: (UIImage) -> Void
    let onCancel: () -> Void

    @State private var phase: Phase = .picking

    private enum Phase {
        case picking
        case preparing
        case cropping(UIImage)
    }

    var body: some View {
        switch phase {
        case .picking:
            MagicGalleryPickerRepresentable(
                sourceType: sourceType,
                onPicked: { image in
                    phase = .preparing
                    Task {
                        let normalized = await image.normalizedForCropping()
                        phase = .cropping(normalized)
                    }
                },
                onCancel: onCancel
            )
        case .preparing:
            Color.black.ignoresSafeArea()
                .overlay { ProgressView().tint(.white) }
        case .cropping(let image):
            MagicGalleryCropView(
                image: image,
                onConfirm: onCaptured,
                onCancel: { phase = .picking }
            )
        }
    }
}

// MARK: - UIImage helper

private extension UIImage {
    func normalizedForCropping() async -> UIImage {
        guard imageOrientation != .up else { return self }
        return await Task.detached(priority: .userInitiated) {
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1.0
            let renderer = UIGraphicsImageRenderer(size: self.size, format: format)
            return renderer.image { _ in self.draw(in: CGRect(origin: .zero, size: self.size)) }
        }.value
    }
}

// MARK: - Picker Representable

private struct MagicGalleryPickerRepresentable: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onPicked: (UIImage) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPicked: onPicked, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(sourceType) ? sourceType : .photoLibrary
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let onPicked: (UIImage) -> Void
        private let onCancel: () -> Void

        init(onPicked: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onPicked = onPicked
            self.onCancel = onCancel
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = info[.originalImage] as? UIImage
            if let image { onPicked(image) } else { onCancel() }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }
    }
}
