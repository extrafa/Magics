//
//  MagicGallerySlotCard.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import SwiftUI

private let statusKey = L10nDomain("magicGallery.status")
private let slotKey = L10nDomain("magicGallery.slot")

struct MagicGallerySlotCard: View {
    let number: Int
    let photo: MagicGalleryPhoto?
    let onTap: (() -> Void)?
    let onDelete: () -> Void

    @State private var isConfirmingDelete = false
    // Read outside the xxxLarge cap applied below, so they are capped by hand: the tile has a fixed height.
    @ScaledMetric(relativeTo: .footnote) private var scaledDeleteCircle: CGFloat = 34
    @ScaledMetric(relativeTo: .footnote) private var scaledDeleteIcon: CGFloat = 14
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
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(slotAccessibilityLabel)
            .accessibilityHint(onTap != nil ? String(localized: slotKey("emptyHint")) : "")
            .accessibilityAddTraits(onTap != nil ? .isButton : [])

            if let photo, photo.isCustom {
                deleteButton
                    .transition(.opacity)
            }
        }
        // One springy animation for the whole slot: deleting, adding or switching the standard set pops instead of snapping.
        .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.6), value: photo)
        // The tile has a fixed height; larger text would cover the photo, and VoiceOver reads the slot label anyway.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private var slotAccessibilityLabel: String {
        let format: String
        switch photo?.source {
        case .standard: format = String(localized: slotKey("standard"))
        case .custom: format = String(localized: slotKey("custom"))
        case nil: format = String(localized: slotKey("empty"))
        }
        return String.localizedStringWithFormat(format, number)
    }

    private var numberBadge: some View {
        Text(verbatim: "\(number)")
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.indigo, in: Capsule(style: .continuous))
    }

    private var deleteButton: some View {
        Button { isConfirmingDelete = true } label: {
            Image(systemName: "trash")
                .font(.system(size: deleteIconSize, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: deleteCircleSize, height: deleteCircleSize)
                .background(.black.opacity(0.38), in: Circle())
                // The tap area is at least 44 pt even though the visible circle is smaller.
                .frame(width: deleteTouchSize, height: deleteTouchSize)
                .contentShape(Rectangle())
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
        // The padding plus the extra touch margin keeps the circle exactly 10 pt from the corner.
        .padding(10 - (deleteTouchSize - deleteCircleSize) / 2)
        .accessibilityLabel(String(localized: "magicGallery.deletePhoto"))
    }

    private var deleteCircleSize: CGFloat { min(scaledDeleteCircle, 48) }
    private var deleteIconSize: CGFloat { min(scaledDeleteIcon, 20) }
    private var deleteTouchSize: CGFloat { max(44, deleteCircleSize + 10) }

    private func sourceBadge(for photo: MagicGalleryPhoto) -> some View {
        Text(photo.isStandard
             ? String(localized: statusKey("standard"))
             : String(localized: statusKey("custom")))
            .font(.caption2.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.black.opacity(0.42), in: Capsule(style: .continuous))
            .padding(10)
    }
}
