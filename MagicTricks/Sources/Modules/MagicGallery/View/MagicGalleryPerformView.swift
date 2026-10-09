//
//  MagicGalleryPerformView.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import SwiftUI
import UIKit

struct MagicGalleryPerformView: View {
    @ObservedObject var vm: MagicGalleryViewModel

    @State private var tapCount = 0
    @State private var pendingSaveTask: Task<Void, Never>?
    @State private var showSaved = false

    private let saveDelay: TimeInterval = 1.2
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let errorFeedback = UINotificationFeedbackGenerator()

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
                .onTapGesture {
                    registerTap()
                }

            if showSaved {
                Image(systemName: "checkmark")
                    .font(.system(size: 44, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.45))
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    .allowsHitTesting(false)
            }

            VStack {
                Spacer()
                tapDots
                    .padding(.bottom, 56)
                    .allowsHitTesting(false)
            }
        }
        .animation(.easeOut(duration: 0.15), value: tapCount)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showSaved)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .magicGalleryAlert(message: $vm.alertMessage)
        .accessDeniedAlert(message: $vm.accessDeniedAlertMessage)
        .keepsScreenAwake()
        .onDisappear {
            pendingSaveTask?.cancel()
            pendingSaveTask = nil
        }
    }

    private var tapDots: some View {
        HStack(spacing: 10) {
            ForEach(1...10, id: \.self) { i in
                Circle()
                    .fill(i <= tapCount ? Color.white.opacity(0.6) : Color.white.opacity(0.1))
                    .frame(width: 7, height: 7)
            }
        }
    }

    private func registerTap() {
        if tapCount >= 10 {
            errorFeedback.notificationOccurred(.error)
            tapCount = 0
            pendingSaveTask?.cancel()
            return
        }
        tapCount += 1
        lightImpact.impactOccurred()
        scheduleSave()
    }

    private func scheduleSave() {
        pendingSaveTask?.cancel()
        pendingSaveTask = Task {
            try? await Task.sleep(for: .seconds(saveDelay))
            guard !Task.isCancelled else { return }
            await save()
        }
    }

    private func save() async {
        let number = tapCount
        tapCount = 0
        let success = await vm.savePhoto(number: number)
        guard !Task.isCancelled else { return }
        if success {
            withAnimation { showSaved = true }
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            withAnimation { showSaved = false }
        } else {
            errorFeedback.notificationOccurred(.error)
        }
    }
}
