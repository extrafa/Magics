//
//  MagicGalleryCapturePanel.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import SwiftUI

private let standardSetKey = L10nDomain("magicGallery.standardSet")
private let gestureKey = L10nDomain("magicGallery.gesture")

struct MagicGalleryCapturePanel: View {
    let usesStandardSet: Bool
    let onToggleStandardSet: (Bool) -> Void
    let gestureMode: MagicGalleryGestureMode
    let onGestureModeChange: (MagicGalleryGestureMode) -> Void
    let canAddMorePhotos: Bool
    let onCapture: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            standardSetControl
            Divider()
            gestureModeControl
            captureButton
        }
        .padding(18)
        .cardSurface(cornerRadius: 22)
    }

    private var standardSetControl: some View {
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

            Spacer(minLength: 8)

            Toggle("", isOn: Binding(
                get: { usesStandardSet },
                set: onToggleStandardSet
            ))
            .labelsHidden()
            .tint(.indigo)
        }
    }

    private var gestureModeControl: some View {
        HStack(spacing: 12) {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(.indigo, in: RoundedRectangle(cornerRadius: 13, style: .continuous))

            Text(String(localized: gestureKey("title")))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.textPrimary)

            Spacer(minLength: 8)

            Picker("", selection: Binding(
                get: { gestureMode },
                set: onGestureModeChange
            )) {
                Text(String(localized: gestureKey("tap"))).tag(MagicGalleryGestureMode.tap)
                Text(String(localized: gestureKey("swipe"))).tag(MagicGalleryGestureMode.swipe)
            }
            .pickerStyle(.segmented)
            .frame(width: 120)
        }
    }

    private var captureButton: some View {
        Button(action: onCapture) {
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
    }
}
