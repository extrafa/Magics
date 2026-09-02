//
//  MagicGalleryViewModel.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

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

    let photoLibrary: MagicGalleryPhotoLibraryManaging
    let photoSaver: MagicGalleryPhotoSaving
    let haptics: HapticNotificationPlaying
    private var preferences: MagicGalleryPreferenceManaging
    var captureFlow = MagicGalleryCaptureFlow()

    init(
        haptics: HapticNotificationPlaying? = nil,
        preferences: MagicGalleryPreferenceManaging = AppPreferences.shared,
        photoLibrary: MagicGalleryPhotoLibraryManaging? = nil,
        photoSaver: MagicGalleryPhotoSaving? = nil
    ) {
        self.haptics = haptics ?? HapticManager.shared
        self.preferences = preferences
        self.photoLibrary = photoLibrary ?? MagicGalleryPhotoLibrary()
        self.photoSaver = photoSaver ?? MagicGallerySystemPhotoSaver()
        self.usesStandardSet = preferences.usesStandardMagicGallerySet
        self.gestureMode = preferences.magicGalleryGestureMode

        loadStoredPhotos()
    }

    var nextAvailableNumber: Int? {
        (1...photoLibrary.maxPhotos).first { number in
            customPhotos.contains { $0.number == number } == false
        }
    }

    func loadStoredPhotos() {
        do {
            customPhotos = try photoLibrary.loadCustomPhotos()
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
}
