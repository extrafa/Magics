//
//  MagicGallerySlotGrid.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import SwiftUI

struct MagicGallerySlotGrid: View {
    let usesStandardSet: Bool
    let selectedPhotoNumber: Int?
    let photoProvider: (Int) -> MagicGalleryPhoto?
    let onSlotTap: (Int) -> Void
    let onDelete: (MagicGalleryPhoto) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(1...10, id: \.self) { number in
                MagicGallerySlotCard(
                    number: number,
                    photo: photoProvider(number),
                    isSelected: selectedPhotoNumber == number,
                    onTap: { onSlotTap(number) },
                    onDelete: { deletePhoto(for: number) }
                )
            }
        }
    }

    private func deletePhoto(for number: Int) {
        guard let photo = photoProvider(number) else { return }
        onDelete(photo)
    }
}
