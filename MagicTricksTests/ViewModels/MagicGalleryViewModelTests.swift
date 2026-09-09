//
//  MagicGalleryViewModelTests.swift
//  MagicTricksTests
//
//  Created by Ross on 28/05/2026.
//

import UIKit
import XCTest
@testable import MagicTricks

@MainActor
final class MagicGalleryViewModelTests: XCTestCase {

    // loadStoredPhotos() is called explicitly from the view's .task, not from init.
    func test_loadStoredPhotos_loadsPhotosAndDefaultPreferences() async {
        let storedPhoto = MagicGalleryPhoto(number: 3, image: Self.image(), fileName: "3.jpg", source: .custom)
        let library = MockMagicGalleryPhotoLibrary(storedPhotos: [storedPhoto])
        let preferences = MockMagicGalleryPreferences()

        let viewModel = MagicGalleryViewModel(
            haptics: MockNotificationHaptics(),
            preferences: preferences,
            photoLibrary: library,
            photoSaver: MockMagicGalleryPhotoSaver()
        )
        await viewModel.loadStoredPhotos()

        XCTAssertEqual(viewModel.customPhotos.map(\.number), [3])
        XCTAssertTrue(viewModel.usesStandardSet)
    }

    // .photoLibrary skips the real AVCaptureDevice permission check .camera would hit.
    func test_startCapture_startsSessionForGivenNumber() async {
        let viewModel = await makeViewModel(usesStandardSet: false)

        viewModel.startCapture(for: 5, sourceType: .photoLibrary)

        XCTAssertEqual(viewModel.activeCaptureSession?.number, 5)
    }

    func test_handleCapturedImage_savesPhoto() async {
        let library = MockMagicGalleryPhotoLibrary()
        let viewModel = await makeViewModel(photoLibrary: library, usesStandardSet: false)

        viewModel.handleCapturedImage(Self.image(), for: 6)
        await flushPendingTasks()

        XCTAssertEqual(library.savedNumbers, [6])
        XCTAssertEqual(viewModel.customPhotos.map(\.number), [6])
        XCTAssertNil(viewModel.alertMessage)
    }

    func test_sequentialCapture_continuesWithNextAvailableNumberAfterDismiss() async {
        let library = MockMagicGalleryPhotoLibrary()
        let viewModel = await makeViewModel(photoLibrary: library, usesStandardSet: false)

        viewModel.startSequentialCapture(sourceType: .photoLibrary)
        XCTAssertEqual(viewModel.activeCaptureSession?.number, 1)

        viewModel.handleCapturedImage(Self.image(), for: 1)
        XCTAssertNil(viewModel.activeCaptureSession)
        await flushPendingTasks()

        viewModel.presentPendingCaptureIfNeeded()

        XCTAssertEqual(library.savedNumbers, [1])
        XCTAssertEqual(viewModel.activeCaptureSession?.number, 2)
    }

    func test_startSequentialCapture_whenAllCustomPhotosReady_showsAlert() async {
        let storedPhotos = (1...10).map {
            MagicGalleryPhoto(number: $0, image: Self.image(), fileName: "\($0).jpg", source: .custom)
        }
        let viewModel = await makeViewModel(storedPhotos: storedPhotos, usesStandardSet: false)

        viewModel.startSequentialCapture(sourceType: .photoLibrary)

        XCTAssertNil(viewModel.activeCaptureSession)
        XCTAssertEqual(viewModel.alertMessage, String(localized: "magicGallery.error.allPhotosReady"))
    }

    func test_deletePhoto_removesCustomPhoto() async {
        let photo = MagicGalleryPhoto(number: 2, image: Self.image(), fileName: "2.jpg", source: .custom)
        let library = MockMagicGalleryPhotoLibrary(storedPhotos: [photo])
        let viewModel = await makeViewModel(photoLibrary: library, storedPhotos: [photo], usesStandardSet: false)

        viewModel.deletePhoto(photo)
        XCTAssertTrue(viewModel.customPhotos.isEmpty)
        await flushPendingTasks()

        XCTAssertEqual(library.deletedNumbers, [2])
    }

    func test_deletePhoto_whenStorageDeleteFails_stillRemovesLocallyAndShowsAlert() async {
        // deletePhoto removes locally right away and doesn't roll back on failure.
        let photo = MagicGalleryPhoto(number: 2, image: Self.image(), fileName: "2.jpg", source: .custom)
        let library = MockMagicGalleryPhotoLibrary(storedPhotos: [photo])
        library.shouldFailDelete = true
        let viewModel = await makeViewModel(photoLibrary: library, storedPhotos: [photo], usesStandardSet: false)

        viewModel.deletePhoto(photo)
        XCTAssertTrue(viewModel.customPhotos.isEmpty)
        await flushPendingTasks()

        XCTAssertEqual(library.deletedNumbers, [2])
        XCTAssertEqual(viewModel.alertMessage, String(localized: "magicGallery.error.deletePhotoFailed"))
    }

    func test_savePhoto_savesImageAndPlaysSuccess() async {
        let photo = MagicGalleryPhoto(number: 1, image: Self.image(), fileName: "1.jpg", source: .custom)
        let saver = MockMagicGalleryPhotoSaver()
        let haptics = MockNotificationHaptics()
        let viewModel = await makeViewModel(
            haptics: haptics,
            photoSaver: saver,
            storedPhotos: [photo],
            usesStandardSet: false
        )

        let success = await viewModel.savePhoto(number: 1)

        XCTAssertTrue(success)
        XCTAssertEqual(saver.savedImagesCount, 1)
        XCTAssertEqual(haptics.successCount, 1)
    }

    func test_savePhoto_whenSaveFails_doesNotPlaySuccessAndShowsAlert() async {
        let photo = MagicGalleryPhoto(number: 1, image: Self.image(), fileName: "1.jpg", source: .custom)
        let saver = MockMagicGalleryPhotoSaver()
        saver.shouldFailSave = true
        let haptics = MockNotificationHaptics()
        let viewModel = await makeViewModel(
            haptics: haptics,
            photoSaver: saver,
            storedPhotos: [photo],
            usesStandardSet: false
        )

        let success = await viewModel.savePhoto(number: 1)

        XCTAssertFalse(success)
        XCTAssertEqual(saver.savedImagesCount, 1)
        XCTAssertEqual(haptics.successCount, 0)
        XCTAssertEqual(viewModel.alertMessage, String(localized: "magicGallery.error.saveToGalleryFailed"))
    }

    private func makeViewModel(
        haptics: MockNotificationHaptics? = nil,
        photoLibrary: MockMagicGalleryPhotoLibrary? = nil,
        photoSaver: MockMagicGalleryPhotoSaver? = nil,
        storedPhotos: [MagicGalleryPhoto] = [],
        usesStandardSet: Bool = false
    ) async -> MagicGalleryViewModel {
        let haptics = haptics ?? MockNotificationHaptics()
        let photoLibrary = photoLibrary ?? MockMagicGalleryPhotoLibrary()
        let photoSaver = photoSaver ?? MockMagicGalleryPhotoSaver()
        photoLibrary.storedPhotos = storedPhotos

        let viewModel = MagicGalleryViewModel(
            haptics: haptics,
            preferences: MockMagicGalleryPreferences(usesStandardMagicGallerySet: usesStandardSet),
            photoLibrary: photoLibrary,
            photoSaver: photoSaver
        )
        await viewModel.loadStoredPhotos()
        return viewModel
    }

    // Lets fire-and-forget Task {} blocks under test finish before we assert on them.
    private func flushPendingTasks() async {
        for _ in 0..<10 { await Task.yield() }
    }

    fileprivate static func image() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }
    }
}

@MainActor
private final class MockMagicGalleryPhotoLibrary: MagicGalleryPhotoLibraryManaging {
    let maxPhotos = 10
    var storedPhotos: [MagicGalleryPhoto]
    var savedNumbers: [Int] = []
    var deletedNumbers: [Int] = []
    var shouldFailDelete = false

    init(storedPhotos: [MagicGalleryPhoto] = []) {
        self.storedPhotos = storedPhotos
    }

    func loadCustomPhotos() throws -> [MagicGalleryPhoto] {
        storedPhotos
    }

    func standardPhoto(for number: Int) -> MagicGalleryPhoto? {
        MagicGalleryPhoto(number: number, image: MagicGalleryViewModelTests.image(), fileName: "\(number).jpg", source: .standard)
    }

    func saveCustomPhoto(_ image: UIImage, for number: Int) async throws -> MagicGalleryPhoto {
        savedNumbers.append(number)
        let photo = MagicGalleryPhoto(number: number, image: image, fileName: "\(number).jpg", source: .custom)
        storedPhotos.append(photo)
        return photo
    }

    func deleteCustomPhoto(_ photo: MagicGalleryPhoto) async throws {
        deletedNumbers.append(photo.number)
        if shouldFailDelete {
            throw MockMagicGalleryError.requestedFailure
        }
        storedPhotos.removeAll { $0.number == photo.number }
    }

    func fullResolutionImage(for photo: MagicGalleryPhoto) async throws -> UIImage {
        photo.image
    }
}

@MainActor
private final class MockMagicGalleryPhotoSaver: MagicGalleryPhotoSaving {
    var savedImagesCount = 0
    var shouldFailSave = false

    func saveToGallery(_ image: UIImage) async throws {
        savedImagesCount += 1
        if shouldFailSave {
            throw MockMagicGalleryError.requestedFailure
        }
    }
}

@MainActor
private final class MockNotificationHaptics: HapticNotificationPlaying {
    var successCount = 0

    func playSuccessNotification() {
        successCount += 1
    }
}

private struct MockMagicGalleryPreferences: MagicGalleryPreferenceManaging {
    var usesStandardMagicGallerySet: Bool = true
    var magicGalleryGestureMode: MagicGalleryGestureMode = .tap
}

private enum MockMagicGalleryError: Error {
    case requestedFailure
}
