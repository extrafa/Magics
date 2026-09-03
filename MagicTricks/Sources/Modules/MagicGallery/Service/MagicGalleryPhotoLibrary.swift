//
//  MagicGalleryPhotoLibrary.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import UIKit

@MainActor
protocol MagicGalleryPhotoLibraryManaging {
    var maxPhotos: Int { get }

    func loadCustomPhotos() async throws -> [MagicGalleryPhoto]
    func standardPhoto(for number: Int) -> MagicGalleryPhoto?
    func saveCustomPhoto(_ image: UIImage, for number: Int) async throws -> MagicGalleryPhoto
    func deleteCustomPhoto(_ photo: MagicGalleryPhoto) async throws
    func fullResolutionImage(for photo: MagicGalleryPhoto) async throws -> UIImage
}

@MainActor
protocol MagicGalleryPhotoSaving {
    func saveToGallery(_ image: UIImage) async throws
}

@MainActor
final class MagicGalleryPhotoLibrary: MagicGalleryPhotoLibraryManaging {
    let maxPhotos = 10

    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func loadCustomPhotos() async throws -> [MagicGalleryPhoto] {
        try ensureStorageDirectoryExists()
        let directoryURL = try storageDirectoryURL()

        return try await Task.detached(priority: .userInitiated) {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )

            return fileURLs.compactMap { url -> MagicGalleryPhoto? in
                guard
                    let image = Self.decodeImage(at: url),
                    let number = Int(url.deletingPathExtension().lastPathComponent)
                else {
                    return nil
                }

                let thumbnail = Self.thumbnail(of: image)
                return MagicGalleryPhoto(number: number, image: thumbnail, fileName: url.lastPathComponent, source: .custom)
            }
            .sorted { $0.number < $1.number }
        }.value
    }

    func standardPhoto(for number: Int) -> MagicGalleryPhoto? {
        guard
            let assetName = Self.standardAssetNames[number],
            let image = UIImage(named: assetName)
        else {
            return nil
        }

        return MagicGalleryPhoto(number: number, image: image, fileName: assetName, source: .standard)
    }

    func saveCustomPhoto(_ image: UIImage, for number: Int) async throws -> MagicGalleryPhoto {
        try ensureStorageDirectoryExists()

        let fileName = "\(number).jpg"
        let url = try storageDirectoryURL().appendingPathComponent(fileName)

        let thumbnail = try await Task.detached(priority: .userInitiated) {
            guard let data = image.jpegData(compressionQuality: 0.92) else {
                throw MagicGalleryPhotoLibraryError.imageEncodingFailed
            }
            try data.write(to: url, options: .atomic)
            return Self.thumbnail(of: image)
        }.value

        return MagicGalleryPhoto(number: number, image: thumbnail, fileName: fileName, source: .custom)
    }

    func deleteCustomPhoto(_ photo: MagicGalleryPhoto) async throws {
        guard photo.isCustom else { return }
        let url = try storageDirectoryURL().appendingPathComponent(photo.fileName)
        try await Task.detached(priority: .utility) {
            try FileManager.default.removeItem(at: url)
        }.value
    }

    func fullResolutionImage(for photo: MagicGalleryPhoto) async throws -> UIImage {
        guard photo.isCustom else { return photo.image }
        let url = try storageDirectoryURL().appendingPathComponent(photo.fileName)

        return try await Task.detached(priority: .userInitiated) {
            guard let image = Self.decodeImage(at: url) else {
                throw MagicGalleryPhotoLibraryError.imageDecodingFailed
            }
            return image
        }.value
    }

    private nonisolated static func decodeImage(at url: URL) -> UIImage? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    private nonisolated static func thumbnail(of image: UIImage) -> UIImage {
        image.preparingThumbnail(of: Self.thumbnailMaxSize) ?? image
    }

    private func storageDirectoryURL() throws -> URL {
        guard let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw MagicGalleryPhotoLibraryError.storageDirectoryUnavailable
        }
        return baseURL.appendingPathComponent("ImpossibleGalleryLibrary", isDirectory: true)
    }

    private func ensureStorageDirectoryExists() throws {
        let storageDirectoryURL = try storageDirectoryURL()

        if !fileManager.fileExists(atPath: storageDirectoryURL.path) {
            try fileManager.createDirectory(at: storageDirectoryURL, withIntermediateDirectories: true)
        }
    }

    private static let thumbnailMaxSize = CGSize(width: 400, height: 400)

    private static let standardAssetNames: [Int: String] = [
        1: "one",
        2: "two",
        3: "three",
        4: "four",
        5: "five",
        6: "six",
        7: "seven",
        8: "eight",
        9: "nine",
        10: "ten"
    ]
}

@MainActor
final class MagicGallerySystemPhotoSaver: NSObject, MagicGalleryPhotoSaving {
    private var continuation: CheckedContinuation<Void, Error>?

    func saveToGallery(_ image: UIImage) async throws {
        guard continuation == nil else {
            throw MagicGalleryPhotoSavingError.saveAlreadyInProgress
        }

        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            UIImageWriteToSavedPhotosAlbum(
                image,
                self,
                #selector(image(_:didFinishSavingWithError:contextInfo:)),
                nil
            )
        }
    }

    @objc private func image(
        _ image: UIImage,
        didFinishSavingWithError error: Error?,
        contextInfo: UnsafeRawPointer
    ) {
        guard let continuation else { return }
        self.continuation = nil

        if let error {
            continuation.resume(throwing: error)
        } else {
            continuation.resume()
        }
    }
}

enum MagicGalleryPhotoLibraryError: Error {
    case storageDirectoryUnavailable
    case imageEncodingFailed
    case imageDecodingFailed
}

enum MagicGalleryPhotoSavingError: Error {
    case saveAlreadyInProgress
}
