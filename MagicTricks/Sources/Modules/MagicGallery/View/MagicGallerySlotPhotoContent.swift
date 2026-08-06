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
        // Color.clear fills the proposed size and always reports that size as its
        // own layout bounds — scaledToFill()'s large intrinsic width never escapes.
        // The image lives in an overlay (doesn't affect layout) and is clipped to
        // the same bounds as the clear color, which equals the card's frame.
        Color.clear
            .overlay {
                Image(uiImage: photo.image)
                    .resizable()
                    .scaledToFill()
                    .clipped()
            }
    }
}
