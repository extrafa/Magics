//
//  PhantomDrawStrokeRendering.swift
//  Magic Tricks
//

import SwiftUI

extension GraphicsContext {
    // Letterboxes to the sender's aspect ratio, when known, instead of stretching per axis.
    func drawStrokes(_ strokes: [DrawingStroke], canvasSize: CGSize, senderAspectRatio: Double? = nil, color: Color = .black) {
        let frame = Self.letterboxedFrame(canvasSize: canvasSize, senderAspectRatio: senderAspectRatio)
        for stroke in strokes {
            guard stroke.points.count > 1 else { continue }
            strokePath(through: stroke.points.map { $0.toCGPoint(in: frame) }, color: color)
        }
    }

    static func letterboxedFrame(canvasSize: CGSize, senderAspectRatio: Double?) -> CGRect {
        guard let senderAspectRatio, senderAspectRatio > 0, canvasSize.width > 0, canvasSize.height > 0 else {
            return CGRect(origin: .zero, size: canvasSize)
        }
        let scale = min(canvasSize.width / CGFloat(senderAspectRatio), canvasSize.height)
        let renderSize = CGSize(width: CGFloat(senderAspectRatio) * scale, height: scale)
        let origin = CGPoint(
            x: (canvasSize.width - renderSize.width) / 2,
            y: (canvasSize.height - renderSize.height) / 2
        )
        return CGRect(origin: origin, size: renderSize)
    }

    func drawActiveStroke(_ points: [CGPoint], color: Color = .black) {
        guard points.count > 1 else { return }
        strokePath(through: points, color: color)
    }

    private func strokePath(through points: [CGPoint], color: Color) {
        var path = Path()
        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        self.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
    }
}
