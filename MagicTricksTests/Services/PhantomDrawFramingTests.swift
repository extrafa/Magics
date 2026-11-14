//
//  PhantomDrawFramingTests.swift
//  MagicTricksTests
//

import CoreGraphics
import XCTest
@testable import MagicTricks

final class PhantomDrawFramingTests: XCTestCase {

    private let sampleStroke = DrawingStroke(
        id: UUID(uuidString: "00000000-0000-0000-0000-0000000000AB")!,
        points: [DrawingPoint(normalizing: CGPoint(x: 10, y: 20), in: CGSize(width: 100, height: 100))]
    )

    func test_encodeThenDecode_roundTripsMessage() throws {
        for message: PhantomDrawMessage in [
            .stroke(sampleStroke),
            .strokeProgress(sampleStroke),
            .clear,
            .sync([]),
            .sync([sampleStroke, sampleStroke])
        ] {
            let frame = try PhantomDrawFraming.encode(message)
            let body = frame.dropFirst(4)

            XCTAssertEqual(try PhantomDrawFraming.decode(Data(body)), message)
        }
    }

    func test_encode_headerIsFourBytesAndMatchesBodyLength() throws {
        let frame = try PhantomDrawFraming.encode(.stroke(sampleStroke))
        let header = Data(frame.prefix(4))
        let body = frame.dropFirst(4)

        XCTAssertEqual(header.count, 4)
        XCTAssertEqual(PhantomDrawFraming.bodyLength(header: header), UInt32(body.count))
    }

    func test_bodyLength_rejectsMalformedHeaders() {
        XCTAssertNil(PhantomDrawFraming.bodyLength(header: Data([1, 2, 3])))
        XCTAssertNil(PhantomDrawFraming.bodyLength(header: Data([1, 2, 3, 4, 5])))
        XCTAssertNil(PhantomDrawFraming.bodyLength(header: Data([0, 0, 0, 0])))
    }

    func test_bodyLength_rejectsOversizedLength() {
        var tooBig = PhantomDrawFraming.maxBodyLength.bigEndian
        let header = Data(bytes: &tooBig, count: 4)

        XCTAssertNil(PhantomDrawFraming.bodyLength(header: header))
    }

    // MARK: - Frame size

    private func stroke(points: Int) -> DrawingStroke {
        DrawingStroke(id: UUID(), points: (0..<points).map { DrawingPoint(x: CGFloat($0) / 7_919, y: CGFloat($0) / 104_729) })
    }

    func test_encode_refusesABodyTheReceiverWouldDrop() {
        XCTAssertThrowsError(try PhantomDrawFraming.encode(.stroke(stroke(points: 25_000))))
    }

    func test_encode_acceptsAMaxLengthStroke() throws {
        let frame = try PhantomDrawFraming.encode(.stroke(stroke(points: PhantomDrawSessionManager.maxPointsPerStroke)))

        XCTAssertNotNil(PhantomDrawFraming.bodyLength(header: Data(frame.prefix(4))))
    }

    func test_syncMessages_withFewStrokes_isOneSync() {
        let strokes = [stroke(points: 10), stroke(points: 20)]

        XCTAssertEqual(PhantomDrawFraming.syncMessages(for: strokes), [.sync(strokes)])
    }

    func test_syncMessages_withNoStrokes_clearsTheCanvas() {
        XCTAssertEqual(PhantomDrawFraming.syncMessages(for: []), [.sync([])])
    }

    func test_syncMessages_withManyStrokes_splitsThemAndKeepsTheOrder() throws {
        let strokes = (0..<30).map { _ in stroke(points: 1_000) }

        let messages = PhantomDrawFraming.syncMessages(for: strokes)

        guard case .sync(let first) = messages[0] else { return XCTFail("The first message must be the .sync") }
        XCTAssertFalse(first.isEmpty)
        XCTAssertGreaterThan(messages.count, 1)
        var rebuilt = first
        for message in messages.dropFirst() {
            guard case .stroke(let next) = message else { return XCTFail("The rest must be single strokes") }
            rebuilt.append(next)
        }
        XCTAssertEqual(rebuilt, strokes)
    }

    func test_syncMessages_everyMessageFitsAFrame() throws {
        let strokes = (0..<30).map { _ in stroke(points: 1_000) }

        for message in PhantomDrawFraming.syncMessages(for: strokes) {
            XCTAssertNoThrow(try PhantomDrawFraming.encode(message))
        }
    }

    func test_syncMessages_leavesOutAStrokeNoFrameCanCarry() {
        let small = stroke(points: 10)

        let messages = PhantomDrawFraming.syncMessages(for: [small, stroke(points: 25_000), small])

        XCTAssertEqual(messages, [.sync([small, small])])
    }
}
