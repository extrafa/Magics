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

    func test_init_loadsStoredPhotosAndDefaultPreferences() {
        let storedPhoto = MagicGalleryPhoto(number: 3, image: Self.image(), fileName: "3.jpg", source: .custom)
        let library = MockMagicGalleryPhotoLibrary(storedPhotos: [storedPhoto])
        let preferences = MockMagicGalleryPreferences()

        let viewModel = MagicGalleryViewModel(
            haptics: MockNotificationHaptics(),
            preferences: preferences,
            photoLibrary: library,
            photoSaver: MockMagicGalleryPhotoSaver()
        )

        XCTAssertEqual(viewModel.customPhotos.map(\.number), [3])
        XCTAssertTrue(viewModel.usesStandardSet)
    }

    func test_handleSlotTap_selectsExistingPhoto() {
        let photo = MagicGalleryPhoto(number: 4, image: Self.image(), fileName: "4.jpg", source: .custom)
        let viewModel = makeViewModel(storedPhotos: [photo], usesStandardSet: false)

        viewModel.handleSlotTap(4)

        XCTAssertEqual(viewModel.selectedPhotoNumber, 4)
        XCTAssertNil(viewModel.activeCaptureSession)
    }

    func test_handleSlotTap_startsCaptureForEmptySlot() {
        let viewModel = makeViewModel(usesStandardSet: false)

        viewModel.handleSlotTap(5)

        XCTAssertEqual(viewModel.activeCaptureSession?.number, 5)
    }

    func test_handleCapturedImage_savesPhotoAndSelectsIt() {
        let library = MockMagicGalleryPhotoLibrary()
        let viewModel = makeViewModel(photoLibrary: library, usesStandardSet: false)

        viewModel.handleCapturedImage(Self.image(), for: 6)

        XCTAssertEqual(library.savedNumbers, [6])
        XCTAssertEqual(viewModel.customPhotos.map(\.number), [6])
        XCTAssertEqual(viewModel.selectedPhotoNumber, 6)
        XCTAssertNil(viewModel.alertMessage)
    }

    func test_sequentialCapture_continuesWithNextAvailableNumberAfterDismiss() {
        let library = MockMagicGalleryPhotoLibrary()
        let viewModel = makeViewModel(photoLibrary: library, usesStandardSet: false)

        viewModel.startSequentialCapture()
        XCTAssertEqual(viewModel.activeCaptureSession?.number, 1)

        viewModel.handleCapturedImage(Self.image(), for: 1)
        XCTAssertNil(viewModel.activeCaptureSession)

        viewModel.presentPendingCaptureIfNeeded()

        XCTAssertEqual(library.savedNumbers, [1])
        XCTAssertEqual(viewModel.activeCaptureSession?.number, 2)
    }

    func test_startSequentialCapture_whenAllCustomPhotosReady_showsAlert() {
        let storedPhotos = (1...10).map {
            MagicGalleryPhoto(number: $0, image: Self.image(), fileName: "\($0).jpg", source: .custom)
        }
        let viewModel = makeViewModel(storedPhotos: storedPhotos, usesStandardSet: false)

        viewModel.startSequentialCapture()

        XCTAssertNil(viewModel.activeCaptureSession)
        XCTAssertEqual(viewModel.alertMessage, String(localized: "magicGallery.error.allPhotosReady"))
    }

    func test_deletePhoto_removesCustomPhotoAndClearsSelection() {
        let photo = MagicGalleryPhoto(number: 2, image: Self.image(), fileName: "2.jpg", source: .custom)
        let library = MockMagicGalleryPhotoLibrary(storedPhotos: [photo])
        let viewModel = makeViewModel(photoLibrary: library, storedPhotos: [photo], usesStandardSet: false)
        viewModel.handleSlotTap(2)

        viewModel.deletePhoto(photo)

        XCTAssertEqual(library.deletedNumbers, [2])
        XCTAssertTrue(viewModel.customPhotos.isEmpty)
        XCTAssertNil(viewModel.selectedPhotoNumber)
    }

    func test_deletePhoto_whenStorageDeleteFails_keepsPhotoAndShowsAlert() {
        let photo = MagicGalleryPhoto(number: 2, image: Self.image(), fileName: "2.jpg", source: .custom)
        let library = MockMagicGalleryPhotoLibrary(storedPhotos: [photo])
        library.shouldFailDelete = true
        let viewModel = makeViewModel(photoLibrary: library, storedPhotos: [photo], usesStandardSet: false)
        viewModel.handleSlotTap(2)

        viewModel.deletePhoto(photo)

        XCTAssertEqual(library.deletedNumbers, [2])
        XCTAssertEqual(viewModel.customPhotos.map(\.number), [2])
        XCTAssertEqual(viewModel.selectedPhotoNumber, 2)
        XCTAssertEqual(viewModel.alertMessage, String(localized: "magicGallery.error.deletePhotoFailed"))
    }

    func test_saveSelectedPhotoToGallery_savesImageAndPlaysSuccess() async {
        let photo = MagicGalleryPhoto(number: 1, image: Self.image(), fileName: "1.jpg", source: .custom)
        let saver = MockMagicGalleryPhotoSaver()
        let haptics = MockNotificationHaptics()
        let viewModel = makeViewModel(
            haptics: haptics,
            photoSaver: saver,
            storedPhotos: [photo],
            usesStandardSet: false
        )
        viewModel.handleSlotTap(1)

        await viewModel.saveSelectedPhotoToGallery()

        XCTAssertEqual(saver.savedImagesCount, 1)
        XCTAssertEqual(haptics.successCount, 1)
    }

    func test_saveSelectedPhotoToGallery_whenSaveFails_doesNotPlaySuccessAndShowsAlert() async {
        let photo = MagicGalleryPhoto(number: 1, image: Self.image(), fileName: "1.jpg", source: .custom)
        let saver = MockMagicGalleryPhotoSaver()
        saver.shouldFailSave = true
        let haptics = MockNotificationHaptics()
        let viewModel = makeViewModel(
            haptics: haptics,
            photoSaver: saver,
            storedPhotos: [photo],
            usesStandardSet: false
        )
        viewModel.handleSlotTap(1)

        await viewModel.saveSelectedPhotoToGallery()

        XCTAssertEqual(saver.savedImagesCount, 1)
        XCTAssertEqual(haptics.successCount, 0)
        XCTAssertEqual(viewModel.alertMessage, String(localized: "magicGallery.error.saveToGalleryFailed"))
    }

    private func makeViewModel(
        haptics: MockNotificationHaptics? = nil,
        photoLibrary: MockMagicGalleryPhotoLibrary? = nil,
        photoSaver: MockMagicGalleryPhotoSaver? = nil,
        storedPhotos: [MagicGalleryPhoto] = [],
        usesStandardSet: Bool = true
    ) -> MagicGalleryViewModel {
        let haptics = haptics ?? MockNotificationHaptics()
        let photoLibrary = photoLibrary ?? MockMagicGalleryPhotoLibrary()
        let photoSaver = photoSaver ?? MockMagicGalleryPhotoSaver()
        photoLibrary.storedPhotos = storedPhotos

        return MagicGalleryViewModel(
            haptics: haptics,
            preferences: MockMagicGalleryPreferences(usesStandardMagicGallerySet: usesStandardSet),
            photoLibrary: photoLibrary,
            photoSaver: photoSaver
        )
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

    func saveCustomPhoto(_ image: UIImage, for number: Int) throws -> MagicGalleryPhoto {
        savedNumbers.append(number)
        let photo = MagicGalleryPhoto(number: number, image: image, fileName: "\(number).jpg", source: .custom)
        storedPhotos.append(photo)
        return photo
    }

    func deleteCustomPhoto(_ photo: MagicGalleryPhoto) throws {
        deletedNumbers.append(photo.number)
        if shouldFailDelete {
            throw MockMagicGalleryError.requestedFailure
        }
        storedPhotos.removeAll { $0.number == photo.number }
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
}

private enum MockMagicGalleryError: Error {
    case requestedFailure
}
