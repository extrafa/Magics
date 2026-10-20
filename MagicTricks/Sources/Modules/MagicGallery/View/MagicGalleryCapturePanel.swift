//
//  MagicGalleryCapturePanel.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import SwiftUI

private let standardSetKey = L10nDomain("magicGallery.standardSet")
private let sourceKey = L10nDomain("magicGallery.source")

struct MagicGalleryCapturePanel: View {
    let usesStandardSet: Bool
    let onToggleStandardSet: (Bool) -> Void
    let canAddMorePhotos: Bool
    let onCapture: (UIImagePickerController.SourceType) -> Void

    @State private var showSourceDialog = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            standardSetControl
            Divider()
            captureButton
        }
        .padding(18)
        .cardSurface(cornerRadius: 22)
    }

    // The toggle takes a column next to the title; at accessibility sizes it moves below so words aren't split.
    @ViewBuilder
    private var standardSetControl: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 12) {
                standardSetLabel
                standardSetToggle
            }
        } else {
            HStack(spacing: 12) {
                standardSetLabel
                Spacer(minLength: 8)
                standardSetToggle
            }
        }
    }

    private var standardSetLabel: some View {
        HStack(spacing: 12) {
            Image(systemName: "rectangle.stack.fill")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(.indigo, in: RoundedRectangle(cornerRadius: 13, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(String(localized: standardSetKey("title")))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.textPrimary)

                Text(String(localized: standardSetKey("description")))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var standardSetToggle: some View {
        Toggle("", isOn: Binding(
            get: { usesStandardSet },
            set: onToggleStandardSet
        ))
        .labelsHidden()
        .tint(.indigo)
    }

    private var captureButton: some View {
        Button { showSourceDialog = true } label: {
            Label(String(localized: "magicGallery.addPhotos"), systemImage: "photo.badge.plus")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(canAddMorePhotos ? Color.buttonPrimary : Color.buttonPrimary.opacity(0.45))
                .foregroundStyle(Color.backgroundScreen)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!canAddMorePhotos)
        // Attached here so the iOS 26 popover points at the button, not at the whole screen.
        .confirmationDialog("", isPresented: $showSourceDialog) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button(String(localized: sourceKey("camera"))) { onCapture(.camera) }
            }
            Button(String(localized: sourceKey("photoLibrary"))) { onCapture(.photoLibrary) }
            Button(String(localized: "common.cancel"), role: .cancel) {}
        }
    }
}
