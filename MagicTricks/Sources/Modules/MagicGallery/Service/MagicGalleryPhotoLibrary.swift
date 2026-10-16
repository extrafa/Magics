//
//  MagicGalleryPhotoLibrary.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import ImageIO
import Photos
import UIKit
import UniformTypeIdentifiers

private let photoImage = KeyDomain("gallery.photo")

@MainActor
protocol PhotoLibraryAuthorizing {
    func hasAddAccess() async -> Bool
}

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
    private var standardThumbnails: [Int: MagicGalleryPhoto] = [:]

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func loadCustomPhotos() async throws -> [MagicGalleryPhoto] {
        try ensureStorageDirectoryExists()
        let directoryURL = try storageDirectoryURL()
        let fileManager = fileManager

        return try await Task.detached(priority: .userInitiated) {
            let fileURLs = try fileManager.contentsOfDirectory(
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
        if let cached = standardThumbnails[number] { return cached }
        guard
            let assetName = Self.standardAssetNames[number],
            let image = UIImage(named: assetName)
        else {
            return nil
        }

        let photo = MagicGalleryPhoto(number: number, image: Self.thumbnail(of: image), fileName: assetName, source: .standard)
        standardThumbnails[number] = photo
        return photo
    }

    func saveCustomPhoto(_ image: UIImage, for number: Int) async throws -> MagicGalleryPhoto {
        try ensureStorageDirectoryExists()

        let fileName = "\(number).jpg"
        let url = try storageDirectoryURL().appendingPathComponent(fileName)

        let thumbnail = try await Task.detached(priority: .userInitiated) {
            let stored = Self.resized(image, maxSide: Self.maxStoredSide)
            guard let data = stored.jpegData(compressionQuality: 0.92) else {
                throw MagicGalleryPhotoLibraryError.imageEncodingFailed
            }
            try data.write(to: url, options: .atomic)
            return Self.thumbnail(of: stored)
        }.value

        return MagicGalleryPhoto(number: number, image: thumbnail, fileName: fileName, source: .custom)
    }

    func deleteCustomPhoto(_ photo: MagicGalleryPhoto) async throws {
        guard photo.isCustom else { return }
        let url = try storageDirectoryURL().appendingPathComponent(photo.fileName)
        let fileManager = fileManager
        try await Task.detached(priority: .utility) {
            do {
                try fileManager.removeItem(at: url)
            } catch let error as NSError where error.domain == NSCocoaErrorDomain && error.code == NSFileNoSuchFileError {
                // Already gone, which is what a delete wants; reporting a failure would bring back a photo with no file.
            }
        }.value
    }

    func fullResolutionImage(for photo: MagicGalleryPhoto) async throws -> UIImage {
        guard photo.isCustom else {
            // The standard photo carries only a thumbnail; the full asset is read when it is actually saved.
            guard let image = UIImage(named: photo.fileName) else { throw MagicGalleryPhotoLibraryError.imageDecodingFailed }
            return image
        }
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

    private nonisolated static func resized(_ image: UIImage, maxSide: CGFloat) -> UIImage {
        guard max(image.size.width, image.size.height) > maxSide else { return image }
        return image.preparingThumbnail(of: CGSize(width: maxSide, height: maxSide)) ?? image
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

    private nonisolated static let thumbnailMaxSize = CGSize(width: 400, height: 400)
    private nonisolated static let maxStoredSide: CGFloat = 2000

    private static let standardAssetNames: [Int: String] = [
        1: photoImage("one"),
        2: photoImage("two"),
        3: photoImage("three"),
        4: photoImage("four"),
        5: photoImage("five"),
        6: photoImage("six"),
        7: photoImage("seven"),
        8: photoImage("eight"),
        9: photoImage("nine"),
        10: photoImage("ten")
    ]
}

// What the Photos app shows for a saved shot: a date a few minutes back and camera-style EXIF.
enum MagicGalleryCameraMetadata {
    static let backdate: TimeInterval = 10 * 60

    static func creationDate(now: Date = Date()) -> Date {
        now.addingTimeInterval(-backdate)
    }

    static func jpegData(for image: UIImage, date: Date, deviceModel: String = UIDevice.current.model) -> Data? {
        let upright = image.imageOrientation == .up ? image : UIGraphicsImageRenderer(size: image.size).image { _ in
            image.draw(at: .zero)
        }
        guard let cgImage = upright.cgImage else { return nil }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        let exifDate = formatter.string(from: date)

        let properties: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.92,
            kCGImagePropertyTIFFDictionary: [
                kCGImagePropertyTIFFMake: "Apple",
                kCGImagePropertyTIFFModel: deviceModel,
                kCGImagePropertyTIFFSoftware: UIDevice.current.systemVersion,
                kCGImagePropertyTIFFDateTime: exifDate
            ],
            kCGImagePropertyExifDictionary: [
                kCGImagePropertyExifDateTimeOriginal: exifDate,
                kCGImagePropertyExifDateTimeDigitized: exifDate,
                kCGImagePropertyExifPixelXDimension: cgImage.width,
                kCGImagePropertyExifPixelYDimension: cgImage.height
            ]
        ]

        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }
}

@MainActor
final class MagicGallerySystemPhotoSaver: MagicGalleryPhotoSaving {
    private var isSaving = false

    func saveToGallery(_ image: UIImage) async throws {
        guard !isSaving else {
            throw MagicGalleryPhotoSavingError.saveAlreadyInProgress
        }
        isSaving = true
        defer { isSaving = false }

        let date = MagicGalleryCameraMetadata.creationDate()
        guard let data = MagicGalleryCameraMetadata.jpegData(for: image, date: date) else {
            throw MagicGalleryPhotoLibraryError.imageEncodingFailed
        }

        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            request.creationDate = date
            request.addResource(with: .photo, data: data, options: nil)
        }
    }
}

@MainActor
final class SystemPhotoLibraryAuthorizer: PhotoLibraryAuthorizing {
    func hasAddAccess() async -> Bool {
        switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
        case .authorized, .limited:
            return true
        case .notDetermined:
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            return status == .authorized || status == .limited
        default:
            return false
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
