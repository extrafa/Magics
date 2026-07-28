//
//  FloatingMotionModifier.swift
//  Magic Tricks
//
//  Created by Ross on 28/05/2026.
//

import SwiftUI

struct FloatingMotionModifier: ViewModifier {
    let phase: Double
    let travel: CGFloat
    let rotation: Double
    let duration: Double

    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .offset(y: isAnimating ? travel : -travel)
            .rotationEffect(.degrees(isAnimating ? rotation : -rotation))
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                    .delay(phase)
                ) {
                    isAnimating = true
                }
            }
    }
}

extension View {
    func floatingMotion(
        phase: Double,
        travel: CGFloat,
        rotation: Double,
        duration: Double
    ) -> some View {
        modifier(FloatingMotionModifier(
            phase: phase,
            travel: travel,
            rotation: rotation,
            duration: duration
        ))
    }
}
