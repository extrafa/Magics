//
//  MagicGalleryViewModel.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import AVFoundation
import Foundation
import UIKit

@MainActor
final class MagicGalleryViewModel: ObservableObject {
    @Published private(set) var customPhotos: [MagicGalleryPhoto] = []
    @Published var activeCaptureSession: MagicGalleryCaptureSession?
    @Published var alertMessage: String?
    @Published var accessDeniedAlertMessage: String?
    @Published private(set) var usesStandardSet: Bool
    @Published private(set) var gestureMode: MagicGalleryGestureMode

    private let photoLibrary: MagicGalleryPhotoLibraryManaging
    private let photoSaver: MagicGalleryPhotoSaving
    private let photoLibraryAuthorizer: PhotoLibraryAuthorizing
    private let haptics: HapticNotificationPlaying
    private var preferences: MagicGalleryPreferenceManaging
    private var captureFlow = MagicGalleryCaptureFlow()

    init(
        haptics: HapticNotificationPlaying? = nil,
        preferences: MagicGalleryPreferenceManaging = AppPreferences.shared,
        photoLibrary: MagicGalleryPhotoLibraryManaging? = nil,
        photoSaver: MagicGalleryPhotoSaving? = nil,
        photoLibraryAuthorizer: PhotoLibraryAuthorizing? = nil
    ) {
        self.haptics = haptics ?? HapticManager.shared
        self.preferences = preferences
        self.photoLibrary = photoLibrary ?? MagicGalleryPhotoLibrary()
        self.photoSaver = photoSaver ?? MagicGallerySystemPhotoSaver()
        self.photoLibraryAuthorizer = photoLibraryAuthorizer ?? SystemPhotoLibraryAuthorizer()
        self.usesStandardSet = preferences.usesStandardMagicGallerySet
        self.gestureMode = preferences.magicGalleryGestureMode
    }

    var nextAvailableNumber: Int? {
        firstAvailableNumber(excluding: Set(customPhotos.map(\.number)))
    }

    private func firstAvailableNumber(excluding takenNumbers: Set<Int>) -> Int? {
        (1...photoLibrary.maxPhotos).first { !takenNumbers.contains($0) }
    }

    func loadStoredPhotos() async {
        do {
            customPhotos = try await photoLibrary.loadCustomPhotos()
        } catch {
            alertMessage = String(localized: "magicGallery.error.loadPhotosFailed")
        }
    }

    func upsert(_ photo: MagicGalleryPhoto) {
        customPhotos.removeAll { $0.number == photo.number }
        customPhotos.append(photo)
        customPhotos.sort { $0.number < $1.number }
    }

    func removeCustomPhoto(number: Int) {
        customPhotos.removeAll { $0.number == number }
    }

    func setStandardSet(_ value: Bool) {
        usesStandardSet = value
        preferences.usesStandardMagicGallerySet = value
    }

    func setGestureMode(_ mode: MagicGalleryGestureMode) {
        gestureMode = mode
        preferences.magicGalleryGestureMode = mode
    }

    var canAddMorePhotos: Bool {
        customPhotos.count < photoLibrary.maxPhotos
    }

    var photosByNumber: [Int: MagicGalleryPhoto] {
        Dictionary(uniqueKeysWithValues: (1...photoLibrary.maxPhotos).compactMap { number in
            photo(for: number).map { (number, $0) }
        })
    }

    func photo(for number: Int) -> MagicGalleryPhoto? {
        if usesStandardSet {
            return photoLibrary.standardPhoto(for: number)
        }
        return customPhotos.first { $0.number == number }
    }

    func startSequentialCapture(sourceType: UIImagePickerController.SourceType = .camera) {
        guard let nextAvailableNumber else {
            alertMessage = String(localized: "magicGallery.error.allPhotosReady")
            return
        }
        beginCapture(sourceType: sourceType) { [weak self] in
            guard let self else { return }
            self.activeCaptureSession = self.captureFlow.startSequential(firstNumber: nextAvailableNumber, sourceType: sourceType)
        }
    }

    func startCapture(for number: Int, sourceType: UIImagePickerController.SourceType = .camera) {
        beginCapture(sourceType: sourceType) { [weak self] in
            guard let self else { return }
            self.activeCaptureSession = self.captureFlow.startSingle(number: number, sourceType: sourceType)
        }
    }

    private func beginCapture(sourceType: UIImagePickerController.SourceType, onReady: @escaping () -> Void) {
        guard sourceType == .camera else {
            onReady()
            return
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            onReady()
        case .notDetermined:
            Task {
                if await AVCaptureDevice.requestAccess(for: .video) {
                    onReady()
                } else {
                    accessDeniedAlertMessage = String(localized: "magicGallery.error.cameraAccessDenied")
                }
            }
        default:
            accessDeniedAlertMessage = String(localized: "magicGallery.error.cameraAccessDenied")
        }
    }

    func handleSlotTap(_ number: Int) {
        startCapture(for: number)
    }

    func handleCaptureCancelled() {
        captureFlow.cancel()
        activeCaptureSession = nil
    }

    func handleCapturedImage(_ image: UIImage, for number: Int) {
        let takenNumbers = Set(customPhotos.map(\.number)).union([number])
        let nextNumber = firstAvailableNumber(excluding: takenNumbers)

        captureFlow.completeCapture(nextAvailableNumber: nextNumber)
        activeCaptureSession = nil

        Task {
            do {
                let photo = try await photoLibrary.saveCustomPhoto(image, for: number)
                upsert(photo)
            } catch {
                alertMessage = String(localized: "magicGallery.error.savePhotoFailed")
            }
        }
    }

    func deletePhoto(_ photo: MagicGalleryPhoto) {
        guard photo.isCustom else { return }
        removeCustomPhoto(number: photo.number)

        Task {
            do {
                try await photoLibrary.deleteCustomPhoto(photo)
            } catch {
                alertMessage = String(localized: "magicGallery.error.deletePhotoFailed")
            }
        }
    }

    func savePhoto(number: Int) async -> Bool {
        guard let photo = photo(for: number) else {
            alertMessage = String(localized: "magicGallery.selectPhotoFirst")
            return false
        }
        guard await photoLibraryAuthorizer.hasAddAccess() else {
            accessDeniedAlertMessage = String(localized: "magicGallery.error.photoLibraryAccessDenied")
            return false
        }
        do {
            let image = try await photoLibrary.fullResolutionImage(for: photo)
            try await photoSaver.saveToGallery(image)
            haptics.playSuccessNotification()
            return true
        } catch {
            alertMessage = String(localized: "magicGallery.error.saveToGalleryFailed")
            return false
        }
    }

    func presentPendingCaptureIfNeeded() {
        guard let pendingSession = captureFlow.pendingSessionIfNeeded(
            isActiveSessionPresent: activeCaptureSession != nil
        ) else { return }
        activeCaptureSession = pendingSession
    }
}
