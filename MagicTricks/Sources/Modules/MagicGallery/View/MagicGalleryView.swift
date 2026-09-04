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

    @State private var showSourceDialog = false

    var body: some View {
        ZStack(alignment: .bottom) {
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

            performButton
        }
        .task { await vm.loadStoredPhotos() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                }
            }
        }
        .confirmationDialog("", isPresented: $showSourceDialog) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Camera") {
                    vm.startSequentialCapture(sourceType: .camera)
                }
            }
            Button("Photo Library") {
                vm.startSequentialCapture(sourceType: .photoLibrary)
            }
            Button("Cancel", role: .cancel) {}
        }
        .fullScreenCover(item: $vm.activeCaptureSession, onDismiss: {
            vm.presentPendingCaptureIfNeeded()
        }) { session in
            MagicGalleryCameraView(
                number: session.number,
                sourceType: session.sourceType,
                onCaptured: { vm.handleCapturedImage($0, for: session.number) },
                onCancel: vm.handleCaptureCancelled
            )
        }
        .magicGalleryAlert(message: $vm.alertMessage)
        .accessDeniedAlert(message: $vm.accessDeniedAlertMessage)
    }

    private var capturePanel: some View {
        MagicGalleryCapturePanel(
            usesStandardSet: vm.usesStandardSet,
            onToggleStandardSet: vm.setStandardSet,
            gestureMode: vm.gestureMode,
            onGestureModeChange: vm.setGestureMode,
            canAddMorePhotos: vm.canAddMorePhotos,
            onCapture: { showSourceDialog = true }
        )
    }

    private var slotGrid: some View {
        MagicGallerySlotGrid(
            customPhotos: vm.customPhotos,
            usesStandardSet: vm.usesStandardSet,
            photoProvider: vm.photo(for:),
            onSlotTap: vm.handleSlotTap,
            onDelete: vm.deletePhoto
        )
    }

    private var performButton: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.background.opacity(0), Color.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 36)
            .allowsHitTesting(false)

            NavigationLink {
                MagicGalleryPerformView(vm: vm)
            } label: {
                Label(String(localized: "magicGallery.perform"), systemImage: "wand.and.stars")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
            }
            .buttonStyle(PrimaryTrickButtonStyle(color: .button))
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .background(Color.background)
        }
    }
}

extension View {
    func magicGalleryAlert(message: Binding<String?>) -> some View {
        alert(String(localized: "instruction.magicGallery.title"), isPresented: Binding(
            get: { message.wrappedValue != nil },
            set: { if !$0 { message.wrappedValue = nil } }
        )) {
            Button(String(localized: "common.ok"), role: .cancel) {
                message.wrappedValue = nil
            }
        } message: {
            Text(message.wrappedValue ?? "")
        }
    }

    func accessDeniedAlert(message: Binding<String?>) -> some View {
        alert(String(localized: "instruction.magicGallery.title"), isPresented: Binding(
            get: { message.wrappedValue != nil },
            set: { if !$0 { message.wrappedValue = nil } }
        )) {
            Button(String(localized: "common.cancel"), role: .cancel) {
                message.wrappedValue = nil
            }
            Button(String(localized: "common.openSettings")) {
                message.wrappedValue = nil
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text(message.wrappedValue ?? "")
        }
    }
}
