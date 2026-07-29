//
//  MagicGallerySlotPhotoContent.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import SwiftUI

struct MagicGallerySlotPhotoContent: View {
    let photo: MagicGalleryPhoto

    var body: some View {
        Group {
            if photo.isLandscape {
                landscapeImage
            } else {
                portraitImage
            }
        }
    }

    private var landscapeImage: some View {
        Image(uiImage: photo.image)
            .resizable()
            .scaledToFit()
            .frame(height: 184)
            .frame(maxWidth: .infinity)
            .padding(8)
    }

    private var portraitImage: some View {
        Image(uiImage: photo.image)
            .resizable()
            .scaledToFill()
            .frame(height: 184)
            .frame(maxWidth: .infinity)
            .clipped()
    }
}
