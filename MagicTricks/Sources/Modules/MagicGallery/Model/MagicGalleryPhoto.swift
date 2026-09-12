//
//  MagicGalleryPhoto.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import UIKit

enum MagicGalleryGestureMode: Int {
    case swipe
    case tap
}

enum MagicGalleryPhotoSource: Equatable {
    case custom
    case standard
}

struct MagicGalleryPhoto: Identifiable, Equatable {
    let number: Int
    let image: UIImage
    let fileName: String
    let source: MagicGalleryPhotoSource

    var id: Int { number }
    var isCustom: Bool { source == .custom }
    var isStandard: Bool { source == .standard }

    static func == (lhs: MagicGalleryPhoto, rhs: MagicGalleryPhoto) -> Bool {
        lhs.number == rhs.number && lhs.fileName == rhs.fileName && lhs.source == rhs.source
    }
}

struct MagicGalleryCaptureSession: Identifiable {
    let number: Int
    let sourceType: UIImagePickerController.SourceType
    var id: Int { number }
}
