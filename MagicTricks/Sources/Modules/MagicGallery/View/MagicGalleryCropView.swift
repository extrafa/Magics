//
//  MagicGalleryCropView.swift
//  Magic Tricks
//
//  Created by Ross on 04/08/2026.
//

import SwiftUI
import UIKit

// MARK: - SwiftUI Wrapper

struct MagicGalleryCropView: UIViewControllerRepresentable {
    let image: UIImage
    let onConfirm: (UIImage) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> MagicGalleryCropViewController {
        MagicGalleryCropViewController(image: image, onConfirm: onConfirm, onCancel: onCancel)
    }

    func updateUIViewController(_ uiViewController: MagicGalleryCropViewController, context: Context) {}
}

// MARK: - Crop View Controller

final class MagicGalleryCropViewController: UIViewController, UIScrollViewDelegate {

    // MARK: Properties

    private let sourceImage: UIImage
    private let onConfirm: (UIImage) -> Void
    private let onCancel: () -> Void

    private var scrollView: UIScrollView!
    private var imageView: UIImageView!
    private var overlayView: CropOverlayView!

    private let framePadding: CGFloat = 24
    private let frameCornerRadius: CGFloat = 20
    private var didLayout = false

    // MARK: Init

    init(image: UIImage, onConfirm: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
        self.sourceImage = image
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !didLayout else { return }
        didLayout = true
        setupScrollView()
        setupOverlay()
        setupButtons()
    }

    // MARK: Crop frame

    private var cropFrame: CGRect {
        let side = view.bounds.width - framePadding * 2
        let topClear = view.safeAreaInsets.top + 66
        let bottomClear = view.bounds.height - view.safeAreaInsets.bottom - 84
        let centerY = (topClear + bottomClear) / 2
        let y = max(centerY - side / 2, topClear)
        return CGRect(x: framePadding, y: y, width: side, height: side)
    }

    // MARK: Setup

    private func setupScrollView() {
        let rect = cropFrame
        let imgSize = sourceImage.size

        let fillScale = max(rect.width / imgSize.width, rect.height / imgSize.height)
        let imageViewSize = CGSize(width: imgSize.width * fillScale, height: imgSize.height * fillScale)

        imageView = UIImageView(frame: CGRect(origin: .zero, size: imageViewSize))
        imageView.image = sourceImage

        scrollView = UIScrollView(frame: rect)
        scrollView.clipsToBounds = true
        scrollView.layer.cornerRadius = frameCornerRadius
        scrollView.layer.cornerCurve = .continuous
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bouncesZoom = true
        scrollView.bounces = false
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.contentSize = imageViewSize
        scrollView.addSubview(imageView)
        view.addSubview(scrollView)

        let offsetX = max((imageViewSize.width - rect.width) / 2, 0)
        let offsetY = max((imageViewSize.height - rect.height) / 2, 0)
        scrollView.setContentOffset(CGPoint(x: offsetX, y: offsetY), animated: false)
    }

    private func setupOverlay() {
        overlayView = CropOverlayView(
            frame: view.bounds,
            cropRect: cropFrame,
            cornerRadius: frameCornerRadius
        )
        overlayView.isUserInteractionEnabled = false
        view.addSubview(overlayView)
    }

    private func setupButtons() {
        let cancelSymbol = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        let cancelButton = UIButton(type: .system)
        cancelButton.setImage(UIImage(systemName: "xmark", withConfiguration: cancelSymbol), for: .normal)
        cancelButton.tintColor = .white
        cancelButton.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        cancelButton.layer.cornerRadius = 20
        cancelButton.layer.cornerCurve = .continuous
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)
        view.addSubview(cancelButton)

        let confirmButton = UIButton(type: .system)
        confirmButton.setTitle("Use Photo", for: .normal)
        confirmButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        confirmButton.tintColor = .white
        confirmButton.backgroundColor = .systemIndigo
        confirmButton.layer.cornerRadius = 16
        confirmButton.layer.cornerCurve = .continuous
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.addTarget(self, action: #selector(handleConfirm), for: .touchUpInside)
        view.addSubview(confirmButton)

        NSLayoutConstraint.activate([
            cancelButton.widthAnchor.constraint(equalToConstant: 40),
            cancelButton.heightAnchor.constraint(equalToConstant: 40),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 14),

            confirmButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            confirmButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            confirmButton.heightAnchor.constraint(equalToConstant: 52),
            confirmButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])
    }

    // MARK: Actions

    @objc private func handleCancel() { onCancel() }
    @objc private func handleConfirm() { onConfirm(extractCrop()) }

    // MARK: Crop extraction

    private func extractCrop() -> UIImage {
        let zoomScale = scrollView.zoomScale
        let offset = scrollView.contentOffset
        let visibleSize = scrollView.bounds.size

        let visibleInView = CGRect(
            x: offset.x / zoomScale,
            y: offset.y / zoomScale,
            width: visibleSize.width / zoomScale,
            height: visibleSize.height / zoomScale
        )

        guard let cgImg = sourceImage.cgImage else { return sourceImage }
        let pixelRatio = CGFloat(cgImg.width) / imageView.bounds.width
        let imageBounds = CGRect(x: 0, y: 0, width: cgImg.width, height: cgImg.height)
        let pixelRect = CGRect(
            x: visibleInView.minX * pixelRatio,
            y: visibleInView.minY * pixelRatio,
            width: visibleInView.width * pixelRatio,
            height: visibleInView.height * pixelRatio
        ).integral.intersection(imageBounds)

        guard let cropped = cgImg.cropping(to: pixelRect) else {
            return sourceImage
        }
        return UIImage(cgImage: cropped)
    }

    // MARK: UIScrollViewDelegate

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }

}

// MARK: - Crop Overlay View

private final class CropOverlayView: UIView {
    private let cropRect: CGRect
    private let cornerRadius: CGFloat

    init(frame: CGRect, cropRect: CGRect, cornerRadius: CGFloat) {
        self.cropRect = cropRect
        self.cornerRadius = cornerRadius
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        UIColor.black.withAlphaComponent(0.60).setFill()
        UIRectFill(rect)

        ctx.setBlendMode(.clear)
        UIBezierPath(roundedRect: cropRect, cornerRadius: cornerRadius).fill()

        ctx.setBlendMode(.normal)
        UIColor.white.withAlphaComponent(0.50).setStroke()
        let border = UIBezierPath(
            roundedRect: cropRect.insetBy(dx: 0.75, dy: 0.75),
            cornerRadius: cornerRadius
        )
        border.lineWidth = 1.5
        border.stroke()
    }
}
