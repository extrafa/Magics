//
//  PhantomDrawStrokeRenderingTests.swift
//  MagicTricksTests
//

import SwiftUI
import XCTest
@testable import MagicTricks

final class PhantomDrawStrokeRenderingTests: XCTestCase {

    func test_letterboxedFrame_withNilAspectRatio_fillsCanvasUnchanged() {
        let canvasSize = CGSize(width: 345, height: 711)

        let frame = GraphicsContext.letterboxedFrame(canvasSize: canvasSize, senderAspectRatio: nil)

        XCTAssertEqual(frame, CGRect(origin: .zero, size: canvasSize))
    }

    func test_letterboxedFrame_withMatchingAspectRatio_fillsCanvasUnchanged() {
        let canvasSize = CGSize(width: 400, height: 800)

        let frame = GraphicsContext.letterboxedFrame(canvasSize: canvasSize, senderAspectRatio: 0.5)

        XCTAssertEqual(frame, CGRect(origin: .zero, size: canvasSize))
    }

    // Sender is nearly square (0.9) into a tall receiver (0.485) - width is the binding constraint.
    func test_letterboxedFrame_withWiderSender_fitsWidthAndPadsVertically() {
        let canvasSize = CGSize(width: 345, height: 711)

        let frame = GraphicsContext.letterboxedFrame(canvasSize: canvasSize, senderAspectRatio: 0.9)

        XCTAssertEqual(frame.width, 345)
        XCTAssertEqual(frame.height, 345 / 0.9, accuracy: 0.001)
        XCTAssertEqual(frame.minX, 0)
        XCTAssertEqual(frame.minY, (711 - frame.height) / 2, accuracy: 0.001)
    }

    // Sender aspect ratio 0.461 (iPhone full-screen) into a receiver at 0.485 - height binds.
    func test_letterboxedFrame_withNarrowerSender_fitsHeightAndPadsHorizontally() {
        let canvasSize = CGSize(width: 345, height: 711)

        let frame = GraphicsContext.letterboxedFrame(canvasSize: canvasSize, senderAspectRatio: 0.461)

        XCTAssertEqual(frame.height, 711)
        XCTAssertEqual(frame.width, 711 * 0.461, accuracy: 0.001)
        XCTAssertEqual(frame.minY, 0)
        XCTAssertEqual(frame.minX, (345 - frame.width) / 2, accuracy: 0.001)
    }

    func test_letterboxedFrame_resultingSizePreservesAspectRatio() {
        let canvasSize = CGSize(width: 393, height: 852)

        let frame = GraphicsContext.letterboxedFrame(canvasSize: canvasSize, senderAspectRatio: 0.7)

        XCTAssertEqual(frame.width / frame.height, 0.7, accuracy: 0.001)
    }
}
