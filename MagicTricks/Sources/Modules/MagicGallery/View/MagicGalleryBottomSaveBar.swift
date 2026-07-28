//
//  MagicGalleryBottomSaveBar.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import SwiftUI

struct MagicGalleryBottomSaveBar: View {
    let saveButtonTitle: String
    let canSave: Bool
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            if !canSave {
                Text(String(localized: "magicGallery.selectPhotoFirst"))
                    .font(.caption)
                    .foregroundStyle(Color.primaryText.opacity(0.55))
            }

            Button(action: onSave) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.headline)

                    Text(saveButtonTitle)
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(canSave ? Color.button : Color.button.opacity(0.45))
                .foregroundStyle(.secondaryText)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canSave)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
        .frame(maxHeight: .infinity, alignment: .bottom)
    }
}
