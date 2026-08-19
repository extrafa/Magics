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

    @State private var swipeCount = 0
    @State private var pendingSaveTask: Task<Void, Never>?
    @State private var showSaved = false

    private let saveDelay: TimeInterval = 1.2
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let errorFeedback = UINotificationFeedbackGenerator()

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onEnded { value in
                            guard abs(value.translation.width) > abs(value.translation.height) else { return }
                            registerSwipe()
                        }
                )

            if showSaved {
                Image(systemName: "checkmark")
                    .font(.system(size: 44, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.45))
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    .allowsHitTesting(false)
            }

            VStack {
                Spacer()
                swipeDots
                    .padding(.bottom, 56)
                    .allowsHitTesting(false)
            }
        }
        .animation(.easeOut(duration: 0.15), value: swipeCount)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showSaved)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var swipeDots: some View {
        HStack(spacing: 10) {
            ForEach(1...10, id: \.self) { i in
                Circle()
                    .fill(i <= swipeCount ? Color.white.opacity(0.6) : Color.white.opacity(0.1))
                    .frame(width: 7, height: 7)
            }
        }
    }

    private func registerSwipe() {
        if swipeCount >= 10 {
            errorFeedback.notificationOccurred(.error)
            swipeCount = 0
            pendingSaveTask?.cancel()
            return
        }
        swipeCount += 1
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
        let number = swipeCount
        swipeCount = 0
        let success = await vm.savePhoto(number: number)
        if success {
            withAnimation { showSaved = true }
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation { showSaved = false }
        } else {
            errorFeedback.notificationOccurred(.error)
        }
    }
}
