//
//  MagicGalleryViewModel+Actions.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import UIKit

extension MagicGalleryViewModel {
    func startSequentialCapture() {
        guard let nextAvailableNumber else {
            alertMessage = String(localized: "magicGallery.error.allPhotosReady")
            return
        }
        activeCaptureSession = captureFlow.startSequential(firstNumber: nextAvailableNumber)
    }

    func startCapture(for number: Int) {
        activeCaptureSession = captureFlow.startSingle(number: number)
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
        do {
            try await photoSaver.saveToGallery(image)
            haptics.playSuccessNotification()
            return true
        } catch {
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
