//
//  MagicGalleryViewModel+Presentation.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import Foundation

extension MagicGalleryViewModel {
    var canAddMorePhotos: Bool {
        customPhotos.count < photoLibrary.maxPhotos
    }

    func photo(for number: Int) -> MagicGalleryPhoto? {
        if usesStandardSet {
            return photoLibrary.standardPhoto(for: number)
        }
        return customPhotos.first { $0.number == number }
    }
}
