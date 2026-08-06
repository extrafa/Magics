//
//  MagicGallerySlotCard.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import SwiftUI

struct MagicGallerySlotCard: View {
    let number: Int
    let photo: MagicGalleryPhoto?
    let isSelected: Bool
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        // Delete button sits in a ZStack OUTSIDE the card's tap Button so that
        // tapping trash never triggers onTap. Nested buttons in SwiftUI can fire
        // both actions; keeping them at the same ZStack level avoids this.
        ZStack(alignment: .topTrailing) {
            Button(action: onTap) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.grayCard)

                    if let photo {
                        MagicGallerySlotPhotoContent(photo: photo)
                    } else {
                        MagicGallerySlotEmptyContent()
                    }
                }
                .frame(height: 184)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            isSelected ? Color.button : Color.primaryText.opacity(0.08),
                            lineWidth: isSelected ? 3 : 1
                        )
                }
                .overlay(alignment: .topLeading) {
                    numberBadge
                        .padding(10)
                }
                .overlay(alignment: .bottomLeading) {
                    if let photo {
                        statusBadge(for: photo)
                    }
                }
            }
            .buttonStyle(.plain)

            if let photo, photo.isCustom {
                deleteButton
            }
        }
    }

    private var numberBadge: some View {
        Text("\(number)")
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.indigo, in: Capsule(style: .continuous))
    }

    private var deleteButton: some View {
        Button(action: onDelete) {
            Image(systemName: "trash")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(.black.opacity(0.38), in: Circle())
        }
        .buttonStyle(.plain)
        .padding(10)
    }

    private func statusBadge(for photo: MagicGalleryPhoto) -> some View {
        Text(statusText(for: photo))
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.black.opacity(0.42), in: Capsule(style: .continuous))
            .padding(10)
    }

    private func statusText(for photo: MagicGalleryPhoto) -> String {
        if isSelected {
            return String(localized: "magicGallery.status.selected")
        }

        return photo.isStandard ? String(localized: "magicGallery.status.standard") : String(localized: "magicGallery.status.custom")
    }
}
