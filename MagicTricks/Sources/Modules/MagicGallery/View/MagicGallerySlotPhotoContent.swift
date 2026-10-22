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
        Color.clear
            .overlay {
                Image(uiImage: photo.image)
                    .resizable()
                    .scaledToFill()
                    .clipped()
            }
    }
}
