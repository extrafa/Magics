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
    case searching
    case connected(peerName: String)
    case failed
}

struct DrawingPoint: Codable, Equatable {
    let x: CGFloat
    let y: CGFloat

    init(normalizing point: CGPoint, in size: CGSize) {
        self.x = size.width > 0 ? point.x / size.width : point.x
        self.y = size.height > 0 ? point.y / size.height : point.y
    }

    func toCGPoint(in size: CGSize) -> CGPoint {
        CGPoint(x: x * size.width, y: y * size.height)
    }
}

struct DrawingStroke: Codable, Identifiable, Equatable {
    let id: UUID
    let points: [DrawingPoint]
}

enum PhantomDrawMessage: Codable {
    case stroke(DrawingStroke)
    case clear
    case sync([DrawingStroke])
}
