//
//  PhantomDrawFraming.swift
//  Magic Tricks
//

import Foundation

// Wire format: 4-byte big-endian body length, then a JSON-encoded PhantomDrawMessage.
enum PhantomDrawFraming {
    static let maxBodyLength: UInt32 = 1_000_000
    // Half the limit, so a .sync stays well clear of it however the strokes encode.
    static let syncBudget = Int(maxBodyLength) / 2

    enum FramingError: Error {
        case bodyTooLarge
    }

    // Refuses a body the receiver would reject anyway: its answer is to drop the connection, so sending it only breaks the session.
    static func encode(_ message: PhantomDrawMessage) throws -> Data {
        let body = try JSONEncoder().encode(message)
        guard body.count < Int(maxBodyLength) else { throw FramingError.bodyTooLarge }
        var length = UInt32(body.count).bigEndian
        return Data(bytes: &length, count: 4) + body
    }

    static func bodyLength(header: Data) -> UInt32? {
        guard header.count == 4 else { return nil }
        let length = header.withUnsafeBytes { $0.loadUnaligned(as: UInt32.self).bigEndian }
        guard length > 0, length < maxBodyLength else { return nil }
        return length
    }

    static func decode(_ body: Data) throws -> PhantomDrawMessage {
        try JSONDecoder().decode(PhantomDrawMessage.self, from: body)
    }

    // Rebuilds a canvas on a new connection without one oversized frame: a .sync with as many strokes as fit the budget, then the
    // rest one by one (.stroke appends to what .sync set). A stroke too big for any frame is left out.
    static func syncMessages(for strokes: [DrawingStroke], budget: Int = syncBudget) -> [PhantomDrawMessage] {
        var synced: [DrawingStroke] = []
        var rest: [DrawingStroke] = []
        var used = 0
        for stroke in strokes {
            guard let size = (try? JSONEncoder().encode(PhantomDrawMessage.stroke(stroke)))?.count,
                  size < Int(maxBodyLength) else { continue }
            if rest.isEmpty, used + size <= budget {
                synced.append(stroke)
                used += size
            } else {
                rest.append(stroke)
            }
        }
        return [.sync(synced)] + rest.map { .stroke($0) }
    }
}
