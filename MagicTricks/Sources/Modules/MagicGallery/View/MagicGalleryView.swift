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

    @State private var captureSource: UIImagePickerController.SourceType = .camera
    @State private var showSourceDialog = false

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
        // Source selection dialog — shown before opening the picker.
        .confirmationDialog("", isPresented: $showSourceDialog) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Camera") {
                    captureSource = .camera
                    vm.startSequentialCapture()
                }
            }
            Button("Photo Library") {
                captureSource = .photoLibrary
                vm.startSequentialCapture()
            }
            Button("Cancel", role: .cancel) {}
        }
        .fullScreenCover(item: $vm.activeCaptureSession, onDismiss: {
            vm.presentPendingCaptureIfNeeded()
        }) { session in
            MagicGalleryCameraView(
                number: session.number,
                sourceType: captureSource,
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
            onCapture: { showSourceDialog = true }
        )
    }

    private var slotGrid: some View {
        MagicGallerySlotGrid(
            customPhotos: vm.customPhotos,
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
            hasPhoto: vm.selectedPhoto != nil,
            isSaving: vm.isSaving,
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
