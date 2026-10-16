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

    func test_startSequentialCapture_withTheStandardSetOn_keepsItUntilAPhotoIsChosen() async {
        let viewModel = await makeViewModel(usesStandardSet: true)

        viewModel.startSequentialCapture(sourceType: .photoLibrary)

        XCTAssertTrue(viewModel.usesStandardSet)
        XCTAssertEqual(viewModel.activeCaptureSession?.number, 1)
    }

    func test_cancellingTheCapture_keepsTheStandardSet() async {
        let viewModel = await makeViewModel(usesStandardSet: true)
        viewModel.startSequentialCapture(sourceType: .photoLibrary)

        viewModel.handleCaptureCancelled()

        XCTAssertTrue(viewModel.usesStandardSet)
        XCTAssertTrue(viewModel.customPhotos.isEmpty)
    }

    func test_choosingAPhoto_withTheStandardSetOn_switchesToCustomPhotos() async {
        let viewModel = await makeViewModel(usesStandardSet: true)
        viewModel.startCapture(for: 4, sourceType: .photoLibrary)
        XCTAssertTrue(viewModel.usesStandardSet)

        await viewModel.handleCapturedImage(Self.image(), for: 4).value

        XCTAssertFalse(viewModel.usesStandardSet)
        XCTAssertEqual(viewModel.customPhotos.map(\.number), [4])
    }

    func test_maxPhotos_comesFromTheLibrary() async {
        let viewModel = await makeViewModel()

        XCTAssertEqual(viewModel.maxPhotos, 10)
    }

    func test_startSequentialCapture_whenAllCustomPhotosAreReady_keepsTheStandardSet() async {
        let stored = (1...10).map {
            MagicGalleryPhoto(number: $0, image: Self.image(), fileName: "\($0).jpg", source: .custom)
        }
        let viewModel = await makeViewModel(storedPhotos: stored, usesStandardSet: true)

        viewModel.startSequentialCapture(sourceType: .photoLibrary)

        XCTAssertTrue(viewModel.usesStandardSet)
        XCTAssertNil(viewModel.activeCaptureSession)
    }

    func test_handleCapturedImage_savesPhoto() async {
        let library = MockMagicGalleryPhotoLibrary()
        let viewModel = await makeViewModel(photoLibrary: library, usesStandardSet: false)

        await viewModel.handleCapturedImage(Self.image(), for: 6).value

        XCTAssertEqual(library.savedNumbers, [6])
        XCTAssertEqual(viewModel.customPhotos.map(\.number), [6])
        XCTAssertNil(viewModel.alertMessage)
    }

    func test_sequentialCapture_continuesWithNextAvailableNumberAfterDismiss() async {
        let library = MockMagicGalleryPhotoLibrary()
        let viewModel = await makeViewModel(photoLibrary: library, usesStandardSet: false)

        viewModel.startSequentialCapture(sourceType: .photoLibrary)
        XCTAssertEqual(viewModel.activeCaptureSession?.number, 1)

        let save = viewModel.handleCapturedImage(Self.image(), for: 1)
        XCTAssertNil(viewModel.activeCaptureSession)
        await save.value

        viewModel.presentPendingCaptureIfNeeded()

        XCTAssertEqual(library.savedNumbers, [1])
        XCTAssertEqual(viewModel.activeCaptureSession?.number, 2)
    }

    func test_sequentialCapture_whenASaveFails_endsTheSeriesAndClosesTheNextCamera() async {
        let library = MockMagicGalleryPhotoLibrary()
        library.shouldFailSave = true
        let viewModel = await makeViewModel(photoLibrary: library, usesStandardSet: false)
        viewModel.startSequentialCapture(sourceType: .photoLibrary)
        let save = viewModel.handleCapturedImage(Self.image(), for: 1)
        // The next camera can already be up by the time the save reports its failure.
        viewModel.presentPendingCaptureIfNeeded()
        XCTAssertEqual(viewModel.activeCaptureSession?.number, 2)

        await save.value

        XCTAssertNil(viewModel.activeCaptureSession)
        XCTAssertEqual(viewModel.alertMessage, String(localized: "magicGallery.error.savePhotoFailed"))
        viewModel.presentPendingCaptureIfNeeded()
        XCTAssertNil(viewModel.activeCaptureSession)
    }

    func test_singleCapture_whenTheSaveFails_showsTheAlertWithoutTouchingAnotherCamera() async {
        let library = MockMagicGalleryPhotoLibrary()
        library.shouldFailSave = true
        let viewModel = await makeViewModel(photoLibrary: library, usesStandardSet: false)

        await viewModel.handleCapturedImage(Self.image(), for: 4).value

        XCTAssertNil(viewModel.activeCaptureSession)
        XCTAssertEqual(viewModel.alertMessage, String(localized: "magicGallery.error.savePhotoFailed"))
        XCTAssertTrue(viewModel.customPhotos.isEmpty)
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

    func test_photosByNumber_whenStandardSetOn_showsTheStandardPhotoInEverySlot() async {
        let custom = MagicGalleryPhoto(number: 3, image: Self.image(), fileName: "3.jpg", source: .custom)
        let viewModel = await makeViewModel(storedPhotos: [custom], usesStandardSet: true)

        let photos = viewModel.photosByNumber

        XCTAssertEqual(Set(photos.keys), Set(1...10))
        XCTAssertTrue(photos.values.allSatisfy(\.isStandard))
    }

    func test_photosByNumber_whenStandardSetOff_showsOnlyTheCustomPhotos() async {
        let stored = [2, 5].map {
            MagicGalleryPhoto(number: $0, image: Self.image(), fileName: "\($0).jpg", source: .custom)
        }
        let viewModel = await makeViewModel(storedPhotos: stored, usesStandardSet: false)

        let photos = viewModel.photosByNumber

        XCTAssertEqual(Set(photos.keys), [2, 5])
        XCTAssertTrue(photos.values.allSatisfy(\.isCustom))
    }

    func test_photosByNumber_followsTheStandardSetToggle() async {
        let custom = MagicGalleryPhoto(number: 4, image: Self.image(), fileName: "4.jpg", source: .custom)
        let viewModel = await makeViewModel(storedPhotos: [custom], usesStandardSet: false)
        XCTAssertEqual(Set(viewModel.photosByNumber.keys), [4])

        viewModel.setStandardSet(true)

        XCTAssertEqual(Set(viewModel.photosByNumber.keys), Set(1...10))
    }

    func test_deletePhoto_removesCustomPhoto() async {
        let photo = MagicGalleryPhoto(number: 2, image: Self.image(), fileName: "2.jpg", source: .custom)
        let library = MockMagicGalleryPhotoLibrary(storedPhotos: [photo])
        let viewModel = await makeViewModel(photoLibrary: library, storedPhotos: [photo], usesStandardSet: false)

        let deletion = viewModel.deletePhoto(photo)
        XCTAssertTrue(viewModel.customPhotos.isEmpty)
        await deletion.value

        XCTAssertEqual(library.deletedNumbers, [2])
    }

    func test_deletePhoto_whenStorageDeleteFails_restoresPhotoAndShowsAlert() async {
        let photo = MagicGalleryPhoto(number: 2, image: Self.image(), fileName: "2.jpg", source: .custom)
        let library = MockMagicGalleryPhotoLibrary(storedPhotos: [photo])
        library.shouldFailDelete = true
        let viewModel = await makeViewModel(photoLibrary: library, storedPhotos: [photo], usesStandardSet: false)

        let deletion = viewModel.deletePhoto(photo)
        XCTAssertTrue(viewModel.customPhotos.isEmpty)
        await deletion.value

        XCTAssertEqual(library.deletedNumbers, [2])
        XCTAssertEqual(viewModel.customPhotos.map(\.number), [2])
        XCTAssertEqual(viewModel.alertMessage, String(localized: "magicGallery.error.deletePhotoFailed"))
    }

    func test_savePhoto_savesImageAndPlaysSuccess() async {
        let photo = MagicGalleryPhoto(number: 1, image: Self.image(), fileName: "1.jpg", source: .custom)
        let saver = MockMagicGalleryPhotoSaver()
        let haptics = MockNotificationHaptics()
        let viewModel = await makeViewModel(
            haptics: haptics,
            photoSaver: saver,
            photoLibraryAuthorizer: MockPhotoLibraryAuthorizer(),
            storedPhotos: [photo],
            usesStandardSet: false
        )

        let success = await viewModel.savePhoto(number: 1)

        XCTAssertTrue(success)
        XCTAssertEqual(saver.savedImagesCount, 1)
        XCTAssertEqual(haptics.successCount, 1)
    }

    func test_prepareForPerformance_withAccess_showsNoAlert() async {
        let authorizer = MockPhotoLibraryAuthorizer()
        let viewModel = await makeViewModel(photoLibraryAuthorizer: authorizer)

        await viewModel.prepareForPerformance()

        XCTAssertEqual(authorizer.requestCount, 1)
        XCTAssertNil(viewModel.accessDeniedAlertMessage)
    }

    func test_prepareForPerformance_withoutAccess_showsTheAccessDeniedAlert() async {
        let authorizer = MockPhotoLibraryAuthorizer()
        authorizer.hasAccess = false
        let viewModel = await makeViewModel(photoLibraryAuthorizer: authorizer)

        await viewModel.prepareForPerformance()

        XCTAssertEqual(
            viewModel.accessDeniedAlertMessage,
            String(localized: "magicGallery.error.photoLibraryAccessDenied")
        )
    }

    func test_savePhoto_withoutAPhotoForTheNumber_asksToAddOneNamingTheNumber() async {
        let saver = MockMagicGalleryPhotoSaver()
        let viewModel = await makeViewModel(photoSaver: saver, usesStandardSet: false)

        let success = await viewModel.savePhoto(number: 7)

        XCTAssertFalse(success)
        XCTAssertEqual(saver.savedImagesCount, 0)
        XCTAssertEqual(
            viewModel.alertMessage,
            String.localizedStringWithFormat(String(localized: "magicGallery.addPhotoFirst"), 7)
        )
        XCTAssertTrue(viewModel.alertMessage?.contains("7") == true)
    }

    func test_savePhoto_whenSaveFails_doesNotPlaySuccessAndShowsAlert() async {
        let photo = MagicGalleryPhoto(number: 1, image: Self.image(), fileName: "1.jpg", source: .custom)
        let saver = MockMagicGalleryPhotoSaver()
        saver.shouldFailSave = true
        let haptics = MockNotificationHaptics()
        let viewModel = await makeViewModel(
            haptics: haptics,
            photoSaver: saver,
            photoLibraryAuthorizer: MockPhotoLibraryAuthorizer(),
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
        photoLibraryAuthorizer: MockPhotoLibraryAuthorizer? = nil,
        storedPhotos: [MagicGalleryPhoto] = [],
        usesStandardSet: Bool = false
    ) async -> MagicGalleryViewModel {
        let haptics = haptics ?? MockNotificationHaptics()
        let photoLibrary = photoLibrary ?? MockMagicGalleryPhotoLibrary()
        let photoSaver = photoSaver ?? MockMagicGalleryPhotoSaver()
        let photoLibraryAuthorizer = photoLibraryAuthorizer ?? MockPhotoLibraryAuthorizer()
        photoLibrary.storedPhotos = storedPhotos

        let viewModel = MagicGalleryViewModel(
            haptics: haptics,
            preferences: MockMagicGalleryPreferences(usesStandardMagicGallerySet: usesStandardSet),
            photoLibrary: photoLibrary,
            photoSaver: photoSaver,
            photoLibraryAuthorizer: photoLibraryAuthorizer
        )
        await viewModel.loadStoredPhotos()
        return viewModel
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
    var shouldFailSave = false

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
        if shouldFailSave {
            throw MockMagicGalleryError.requestedFailure
        }
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
private final class MockPhotoLibraryAuthorizer: PhotoLibraryAuthorizing {
    var hasAccess = true
    private(set) var requestCount = 0

    func hasAddAccess() async -> Bool {
        requestCount += 1
        return hasAccess
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

@MainActor
final class MagicGalleryPhotoLibraryStandardPhotoTests: XCTestCase {
    func test_standardPhoto_isAThumbnail_whileTheFullImageStaysFullSize() async throws {
        let library = MagicGalleryPhotoLibrary()

        let photo = try XCTUnwrap(library.standardPhoto(for: 1))
        let full = try await library.fullResolutionImage(for: photo)

        XCTAssertLessThanOrEqual(max(photo.image.size.width, photo.image.size.height), 400)
        XCTAssertGreaterThan(max(full.size.width, full.size.height), 400)
    }

    func test_standardPhoto_returnsTheSamePhotoOnRepeatedCalls() throws {
        let library = MagicGalleryPhotoLibrary()

        let first = try XCTUnwrap(library.standardPhoto(for: 3))
        let second = try XCTUnwrap(library.standardPhoto(for: 3))

        XCTAssertTrue(first.image === second.image)
    }
}

final class MagicGalleryCameraMetadataTests: XCTestCase {
    func test_creationDate_isTenMinutesBeforeNow() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)

        XCTAssertEqual(MagicGalleryCameraMetadata.creationDate(now: now), now.addingTimeInterval(-600))
    }

    func test_jpegData_carriesCameraStyleExif() throws {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 30, height: 40)).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 30, height: 40))
        }
        let date = Date(timeIntervalSince1970: 1_800_000_000)

        let data = try XCTUnwrap(MagicGalleryCameraMetadata.jpegData(for: image, date: date, deviceModel: "iPhone"))
        let source = try XCTUnwrap(CGImageSourceCreateWithData(data as CFData, nil))
        let properties = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
        let tiff = try XCTUnwrap(properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any])
        let exif = try XCTUnwrap(properties[kCGImagePropertyExifDictionary] as? [CFString: Any])

        XCTAssertEqual(tiff[kCGImagePropertyTIFFMake] as? String, "Apple")
        XCTAssertEqual(tiff[kCGImagePropertyTIFFModel] as? String, "iPhone")
        XCTAssertNotNil(exif[kCGImagePropertyExifDateTimeOriginal] as? String)
        XCTAssertEqual(exif[kCGImagePropertyExifDateTimeOriginal] as? String, tiff[kCGImagePropertyTIFFDateTime] as? String)
        XCTAssertEqual(properties[kCGImagePropertyPixelWidth] as? Int, Int(image.size.width * image.scale))
    }

    func test_jpegData_bakesInTheOrientation() throws {
        let landscape = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 30)).image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 40, height: 30))
        }
        let rotated = UIImage(cgImage: try XCTUnwrap(landscape.cgImage), scale: landscape.scale, orientation: .right)

        let data = try XCTUnwrap(MagicGalleryCameraMetadata.jpegData(for: rotated, date: Date()))
        let decoded = try XCTUnwrap(UIImage(data: data))

        XCTAssertGreaterThan(decoded.size.height, decoded.size.width)
        XCTAssertEqual(decoded.imageOrientation, .up)
    }
}
