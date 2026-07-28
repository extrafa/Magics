//
//  MagicGalleryView.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import SwiftUI

struct MagicGalleryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = MagicGalleryViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        capturePanel
                        slotGrid
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 120)
                }

                if vm.selectedPhoto != nil { bottomSaveButton }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .fullScreenCover(item: $vm.activeCaptureSession, onDismiss: {
            vm.presentPendingCaptureIfNeeded()
        }) { session in
            MagicGalleryCameraView(
                number: session.number,
                onCaptured: { vm.handleCapturedImage($0, for: session.number) },
                onCancel: vm.handleCaptureCancelled
            )
        }
        .alert(String(localized: "instruction.magicGallery.title"), isPresented: alertBinding) {
            Button(String(localized: "common.ok"), role: .cancel) {
                vm.alertMessage = nil
            }
        } message: {
            Text(vm.alertMessage ?? "")
        }
    }

    private var capturePanel: some View {
        MagicGalleryCapturePanel(
            usesStandardSet: vm.usesStandardSet,
            onToggleStandardSet: vm.setStandardSet,
            captureButtonTitle: vm.captureButtonTitle,
            canAddMorePhotos: vm.canAddMorePhotos,
            onCapture: vm.startSequentialCapture
        )
    }

    private var slotGrid: some View {
        MagicGallerySlotGrid(
            usesStandardSet: vm.usesStandardSet,
            selectedPhotoNumber: vm.selectedPhoto?.number,
            photoProvider: vm.photo(for:),
            onSlotTap: vm.handleSlotTap,
            onDelete: vm.deletePhoto
        )
    }

    private var bottomSaveButton: some View {
        MagicGalleryBottomSaveBar(
            saveButtonTitle: vm.saveButtonTitle,
            canSave: vm.selectedPhoto != nil,
            onSave: {
                Task {
                    await vm.saveSelectedPhotoToGallery()
                }
            }
        )
    }

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { vm.alertMessage != nil },
            set: { newValue in
                if !newValue { vm.alertMessage = nil }
            }
        )
    }
}
