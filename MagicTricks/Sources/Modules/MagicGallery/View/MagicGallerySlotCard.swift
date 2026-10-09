//
//  MagicGallerySlotCard.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import SwiftUI

private let statusKey = L10nDomain("magicGallery.status")

struct MagicGallerySlotCard: View {
    let number: Int
    let photo: MagicGalleryPhoto?
    let onTap: (() -> Void)?
    let onDelete: () -> Void

    @State private var isConfirmingDelete = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                if let photo {
                    MagicGallerySlotPhotoContent(photo: photo)
                        .transition(.opacity.combined(with: .scale(scale: 0.85)))
                } else {
                    MagicGallerySlotEmptyContent()
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .frame(height: 184)
            // A background, not a ZStack child: otherwise the photo that is fading out sits under the opaque fill.
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.cardBackground)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.textPrimary.opacity(0.08), lineWidth: 1)
            }
            .overlay(alignment: .topLeading) {
                numberBadge.padding(10)
            }
            .overlay(alignment: .bottomLeading) {
                if let photo {
                    sourceBadge(for: photo)
                        .transition(.opacity)
                }
            }
            .onTapGesture {
                onTap?()
            }
            .accessibilityElement(children: onTap != nil ? .combine : .contain)
            .accessibilityAddTraits(onTap != nil ? .isButton : [])

            if let photo, photo.isCustom {
                deleteButton
                    .transition(.opacity)
            }
        }
        // One springy animation for the whole slot: deleting, adding or switching the standard set pops instead of snapping.
        .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.6), value: photo)
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
        Button { isConfirmingDelete = true } label: {
            Image(systemName: "trash")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(.black.opacity(0.38), in: Circle())
        }
        .buttonStyle(.plain)
        // On iOS 26 the dialog is a popover pointing at the view it is attached to, so it lives on the button itself.
        .confirmationDialog(
            String(localized: "magicGallery.deletePhoto.confirm"),
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button(String(localized: "magicGallery.deletePhoto"), role: .destructive, action: onDelete)
            Button(String(localized: "common.cancel"), role: .cancel) {}
        }
        .padding(10)
        .accessibilityLabel(String(localized: "magicGallery.deletePhoto"))
    }

    private func sourceBadge(for photo: MagicGalleryPhoto) -> some View {
        Text(photo.isStandard
             ? String(localized: statusKey("standard"))
             : String(localized: statusKey("custom")))
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.black.opacity(0.42), in: Capsule(style: .continuous))
            .padding(10)
    }
}
