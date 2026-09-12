//
//  PhantomDrawStrokeRendering.swift
//  Magic Tricks
//

import SwiftUI

extension GraphicsContext {
    func drawStrokes(_ strokes: [DrawingStroke], canvasSize: CGSize, color: Color = .black) {
        for stroke in strokes {
            guard stroke.points.count > 1 else { continue }
            var path = Path()
            path.move(to: stroke.points[0].toCGPoint(in: canvasSize))
            for point in stroke.points.dropFirst() {
                path.addLine(to: point.toCGPoint(in: canvasSize))
            }
            self.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
        }
    }

    func drawActiveStroke(_ points: [CGPoint], color: Color = .black) {
        guard points.count > 1 else { return }
        var path = Path()
        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        self.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
    }
}
