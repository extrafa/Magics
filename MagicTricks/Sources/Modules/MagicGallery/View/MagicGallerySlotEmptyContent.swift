//
//  MagicGallerySlotEmptyContent.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import SwiftUI

struct MagicGallerySlotEmptyContent: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.fill")
                .font(.title2)
                .foregroundStyle(.indigo)

            Text(String(localized: "magicGallery.emptySlot"))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.primaryText)

            Text(String(localized: "magicGallery.tapToCapture"))
                .font(.caption)
                .foregroundStyle(Color.primaryText.opacity(0.55))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
