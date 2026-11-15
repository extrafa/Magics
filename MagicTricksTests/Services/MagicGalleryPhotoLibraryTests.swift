//
//  MagicGalleryPhotoLibraryTests.swift
//  MagicTricksTests
//

import XCTest
@testable import MagicTricks

@MainActor
final class MagicGalleryPhotoLibraryTests: XCTestCase {

    private var baseURL: URL!
    private var library: MagicGalleryPhotoLibrary!

    override func setUp() {
        super.setUp()
        baseURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
        library = MagicGalleryPhotoLibrary(fileManager: TemporaryDirectoryFileManager(baseURL: baseURL))
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: baseURL)
        super.tearDown()
    }

    func test_deleteCustomPhoto_removesTheFile() async throws {
        let photo = try await library.saveCustomPhoto(Self.image(), for: 3)
        let fileURL = baseURL.appendingPathComponent("ImpossibleGalleryLibrary").appendingPathComponent(photo.fileName)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))

        try await library.deleteCustomPhoto(photo)

        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
    }

    func test_deleteCustomPhoto_whenTheFileIsAlreadyGone_doesNotThrow() async throws {
        let photo = try await library.saveCustomPhoto(Self.image(), for: 5)
        try await library.deleteCustomPhoto(photo)

        // A second delete of the same photo must not report a failure: the file is already gone.
        try await library.deleteCustomPhoto(photo)
    }

    private static func image() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }
    }
}

private final class TemporaryDirectoryFileManager: FileManager {
    private let baseURL: URL

    init(baseURL: URL) {
        self.baseURL = baseURL
        super.init()
    }

    override func urls(for directory: FileManager.SearchPathDirectory, in domainMask: FileManager.SearchPathDomainMask) -> [URL] {
        [baseURL]
    }
}
