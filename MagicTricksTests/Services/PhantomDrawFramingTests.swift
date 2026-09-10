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
}
