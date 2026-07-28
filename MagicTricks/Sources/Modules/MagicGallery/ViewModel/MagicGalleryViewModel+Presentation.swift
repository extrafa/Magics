//
//  MagicGalleryViewModel+Presentation.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import Foundation

extension MagicGalleryViewModel {
    var selectedPhoto: MagicGalleryPhoto? {
        guard let selectedPhotoNumber else { return nil }
        return photo(for: selectedPhotoNumber)
    }

    var canAddMorePhotos: Bool {
        customPhotos.count < photoLibrary.maxPhotos
    }

    var progressText: String {
        if usesStandardSet {
            return customPhotos.isEmpty
                ? String(localized: "magicGallery.progress.standardReady")
                : String.localizedStringWithFormat(String(localized: "magicGallery.progress.standardCustom"), customPhotos.count)
        }

        return String.localizedStringWithFormat(String(localized: "magicGallery.progress.customReady"), customPhotos.count)
    }

    var captureButtonTitle: String {
        String(localized: "magicGallery.addPhotos")
    }

    var saveButtonTitle: String {
        selectedPhoto.map {
            String.localizedStringWithFormat(String(localized: "magicGallery.saveNumberToGallery"), $0.number)
        } ?? String(localized: "magicGallery.saveToGallery")
    }

    func photo(for number: Int) -> MagicGalleryPhoto? {
        if usesStandardSet {
            return photoLibrary.standardPhoto(for: number)
        }

        return customPhotos.first { $0.number == number }
    }
}
