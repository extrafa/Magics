//
//  PhantomDrawFraming.swift
//  Magic Tricks
//

import Foundation

// Wire format: 4-byte big-endian body length, then a JSON-encoded PhantomDrawMessage.
enum PhantomDrawFraming {
    static let maxBodyLength: UInt32 = 1_000_000

    enum FramingError: Error {
        case bodyTooLarge
    }

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
}
