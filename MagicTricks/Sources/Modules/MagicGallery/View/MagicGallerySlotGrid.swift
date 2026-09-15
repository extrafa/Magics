//
//  MagicGallerySlotGrid.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import SwiftUI

struct MagicGallerySlotGrid: View {
    let photos: [Int: MagicGalleryPhoto]
    let onSlotTap: (Int) -> Void
    let onDelete: (MagicGalleryPhoto) -> Void

    private static let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: Self.columns, spacing: 12) {
            ForEach(1...10, id: \.self) { number in
                let photo = photos[number]
                MagicGallerySlotCard(
                    number: number,
                    photo: photo,
                    onTap: photo == nil ? { onSlotTap(number) } : nil,
                    onDelete: { deletePhoto(for: number) }
                )
            }
        }
    }

    private func deletePhoto(for number: Int) {
        guard let photo = photos[number] else { return }
        onDelete(photo)
    }
}
