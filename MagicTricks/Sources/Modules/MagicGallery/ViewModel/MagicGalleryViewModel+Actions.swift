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
        if let photo = photo(for: number) {
            selectedPhotoNumber = photo.number
        } else {
            startCapture(for: number)
        }
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
                selectedPhotoNumber = photo.number
            } catch {
                alertMessage = String(localized: "magicGallery.error.savePhotoFailed")
            }
        }
    }

    func deletePhoto(_ photo: MagicGalleryPhoto) {
        guard photo.isCustom else { return }

        removeCustomPhoto(number: photo.number)
        if selectedPhotoNumber == photo.number {
            selectedPhotoNumber = nil
        }

        Task {
            do {
                try await photoLibrary.deleteCustomPhoto(photo)
            } catch {
                alertMessage = String(localized: "magicGallery.error.deletePhotoFailed")
            }
        }
    }

    func saveSelectedPhotoToGallery() async {
        guard !isSaving else { return }
        guard let image = selectedPhoto?.image else {
            alertMessage = String(localized: "magicGallery.selectPhotoFirst")
            return
        }

        isSaving = true
        defer {
            Task { @MainActor in
                try? await Task.sleep(milliseconds: 800)
                isSaving = false
            }
        }

        do {
            try await photoSaver.saveToGallery(image)
            haptics.playSuccessNotification()
        } catch {
            alertMessage = String(localized: "magicGallery.error.saveToGalleryFailed")
        }
    }

    func presentPendingCaptureIfNeeded() {
        guard let pendingSession = captureFlow.pendingSessionIfNeeded(
            isActiveSessionPresent: activeCaptureSession != nil
        ) else { return }

        activeCaptureSession = pendingSession
    }
}
