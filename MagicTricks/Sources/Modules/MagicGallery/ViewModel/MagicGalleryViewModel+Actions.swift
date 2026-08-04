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
        do {
            let photo = try photoLibrary.saveCustomPhoto(image, for: number)
            upsert(photo)
            selectedPhotoNumber = photo.number
        } catch {
            alertMessage = String(localized: "magicGallery.error.savePhotoFailed")
            captureFlow.failCapture()
            activeCaptureSession = nil
            return
        }

        captureFlow.completeCapture(nextAvailableNumber: nextAvailableNumber)
        activeCaptureSession = nil
    }

    func deletePhoto(_ photo: MagicGalleryPhoto) {
        guard photo.isCustom else { return }

        do {
            try photoLibrary.deleteCustomPhoto(photo)
        } catch {
            alertMessage = String(localized: "magicGallery.error.deletePhotoFailed")
            return
        }

        removeCustomPhoto(number: photo.number)

        if selectedPhotoNumber == photo.number {
            selectedPhotoNumber = nil
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
                // Short cooldown prevents save spam and repeated haptics
                try? await Task.sleep(for: .milliseconds(800))
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
