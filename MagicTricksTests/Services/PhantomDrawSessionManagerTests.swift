//
//  PhantomDrawSessionManagerTests.swift
//  MagicTricksTests
//

import XCTest
@testable import MagicTricks

@MainActor
final class PhantomDrawSessionManagerTests: XCTestCase {

    private let manager = PhantomDrawSessionManager()

    func test_sanitized_withInRangeStroke_returnsItUnchanged() {
        let stroke = DrawingStroke(id: UUID(), points: [DrawingPoint(x: 0.2, y: 0.8)])

        XCTAssertEqual(manager.sanitized(stroke), stroke)
    }

    func test_sanitized_withOutOfBoundsCoordinates_clampsToUnitRange() throws {
        let stroke = DrawingStroke(
            id: UUID(),
            points: [DrawingPoint(x: -5, y: 1e300), DrawingPoint(x: 0.5, y: -0.001)]
        )

        let sanitized = try XCTUnwrap(manager.sanitized(stroke))

        XCTAssertEqual(sanitized.points[0].x, 0)
        XCTAssertEqual(sanitized.points[0].y, 1)
        XCTAssertEqual(sanitized.points[1].x, 0.5)
        XCTAssertEqual(sanitized.points[1].y, 0)
    }

    func test_sanitized_withEmptyPoints_returnsNil() {
        let stroke = DrawingStroke(id: UUID(), points: [])

        XCTAssertNil(manager.sanitized(stroke))
    }

    func test_sanitized_withTooManyPoints_returnsNil() {
        let stroke = DrawingStroke(
            id: UUID(),
            points: (0...PhantomDrawSessionManager.maxPointsPerStroke).map { _ in DrawingPoint(x: 0, y: 0) }
        )

        XCTAssertNil(manager.sanitized(stroke))
    }

    func test_sanitized_withMaxAllowedPoints_returnsIt() {
        let stroke = DrawingStroke(
            id: UUID(),
            points: (0..<PhantomDrawSessionManager.maxPointsPerStroke).map { _ in DrawingPoint(x: 0, y: 0) }
        )

        XCTAssertNotNil(manager.sanitized(stroke))
    }
}
