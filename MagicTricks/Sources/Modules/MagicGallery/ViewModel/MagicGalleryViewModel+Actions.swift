//
//  MagicGalleryViewModel+Actions.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import AVFoundation
import Photos
import UIKit

extension MagicGalleryViewModel {
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
        let nextNumber = (1...photoLibrary.maxPhotos).first { !takenNumbers.contains($0) }

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
        guard let image = photo(for: number)?.image else { return false }
        guard await hasPhotoLibraryAddAccess() else {
            accessDeniedAlertMessage = String(localized: "magicGallery.error.photoLibraryAccessDenied")
            return false
        }
        do {
            try await photoSaver.saveToGallery(image)
            haptics.playSuccessNotification()
            return true
        } catch {
            return false
        }
    }

    private func hasPhotoLibraryAddAccess() async -> Bool {
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

    func presentPendingCaptureIfNeeded() {
        guard let pendingSession = captureFlow.pendingSessionIfNeeded(
            isActiveSessionPresent: activeCaptureSession != nil
        ) else { return }
        activeCaptureSession = pendingSession
    }
}
