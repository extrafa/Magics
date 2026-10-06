//
//  ShimmerModifier.swift
//  Magic Tricks
//

import SwiftUI

struct ShimmerModifier<S: Shape>: ViewModifier {
    let shape: S
    let isActive: Bool
    let highlight: Color
    let blend: BlendMode

    @State private var sweeping = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, highlight, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.5)
                    .offset(x: sweeping ? geo.size.width * 1.2 : -geo.size.width * 0.5)
                }
                .clipShape(shape)
                .blendMode(blend)
                .allowsHitTesting(false)
            }
            .task(id: isActive) { await loop() }
    }

    private func loop() async {
        guard isActive, !reduceMotion else { return }
        while !Task.isCancelled {
            try? await Task.sleep(seconds: 2.5)
            withAnimation(.easeInOut(duration: 0.75)) { sweeping = true }
            try? await Task.sleep(milliseconds: 950)
            sweeping = false
        }
    }
}

extension View {
    func shimmer<S: Shape>(
        in shape: S,
        isActive: Bool = true,
        highlight: Color = .white.opacity(0.38),
        blend: BlendMode = .screen
    ) -> some View {
        modifier(ShimmerModifier(shape: shape, isActive: isActive, highlight: highlight, blend: blend))
    }
}
