import UIKit

@MainActor
protocol MagicGalleryPhotoLibraryManaging {
    var maxPhotos: Int { get }

    func loadCustomPhotos() throws -> [MagicGalleryPhoto]
    func standardPhoto(for number: Int) -> MagicGalleryPhoto?
    func saveCustomPhoto(_ image: UIImage, for number: Int) throws -> MagicGalleryPhoto
    func deleteCustomPhoto(_ photo: MagicGalleryPhoto) throws
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

    func loadCustomPhotos() throws -> [MagicGalleryPhoto] {
        try ensureStorageDirectoryExists()

        let fileURLs = try fileManager.contentsOfDirectory(
            at: storageDirectoryURL(),
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        return fileURLs.compactMap { url in
            guard
                let data = try? Data(contentsOf: url),
                let image = UIImage(data: data),
                let number = Int(url.deletingPathExtension().lastPathComponent)
            else {
                return nil
            }

            return MagicGalleryPhoto(number: number, image: image, fileName: url.lastPathComponent, source: .custom)
        }
        .sorted { $0.number < $1.number }
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

    func saveCustomPhoto(_ image: UIImage, for number: Int) throws -> MagicGalleryPhoto {
        try ensureStorageDirectoryExists()

        let fileName = "\(number).jpg"
        let url = try storageDirectoryURL().appendingPathComponent(fileName)

        guard let data = image.jpegData(compressionQuality: 0.92) else {
            throw MagicGalleryPhotoLibraryError.imageEncodingFailed
        }

        try data.write(to: url, options: .atomic)
        return MagicGalleryPhoto(number: number, image: image, fileName: fileName, source: .custom)
    }

    func deleteCustomPhoto(_ photo: MagicGalleryPhoto) throws {
        guard photo.isCustom else { return }
        try fileManager.removeItem(at: storageDirectoryURL().appendingPathComponent(photo.fileName))
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
}

enum MagicGalleryPhotoSavingError: Error {
    case saveAlreadyInProgress
}
