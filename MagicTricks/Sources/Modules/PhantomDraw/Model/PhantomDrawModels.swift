//
//  PhantomDrawModels.swift
//  Magic Tricks
//

import Foundation
import CoreGraphics

enum PhantomDrawRole {
    case receiver
    case sender
}

enum PhantomDrawConnectionState: Equatable {
    case idle
    case enteringCode
    case searching
    case connected(peerName: String)
    case failed
}

struct DrawingPoint: Codable, Equatable {
    let x: CGFloat
    let y: CGFloat

    init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
    }

    init(normalizing point: CGPoint, in size: CGSize) {
        self.x = size.width > 0 ? point.x / size.width : point.x
        self.y = size.height > 0 ? point.y / size.height : point.y
    }

    func toCGPoint(in size: CGSize) -> CGPoint {
        CGPoint(x: x * size.width, y: y * size.height)
    }

    func toCGPoint(in rect: CGRect) -> CGPoint {
        CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
    }
}

struct DrawingStroke: Codable, Identifiable, Equatable {
    let id: UUID
    let points: [DrawingPoint]
}

enum PhantomDrawMessage: Codable, Equatable {
    case stroke(DrawingStroke)
    case strokeProgress(DrawingStroke)
    case clear
    case sync([DrawingStroke])
    case canvasAspectRatio(Double)
}
