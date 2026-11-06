//
//  OnboardingAppearTransition.swift
//  Magic Tricks
//

import SwiftUI

extension Animation {
    static let onboardingAppear = Animation.spring(response: 0.55, dampingFraction: 0.82)
}

struct OnboardingAppearTransition: ViewModifier {
    let appeared: Bool
    var offset: CGFloat = 14
    var delay: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // With Reduce Motion the content only fades in: no slide, no spring, no stagger.
    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared || reduceMotion ? 0 : offset)
            .animation(reduceMotion ? .easeOut(duration: 0.2) : .onboardingAppear.delay(delay), value: appeared)
    }
}

extension View {
    func onboardingAppear(_ appeared: Bool, offset: CGFloat = 14, delay: Double = 0) -> some View {
        modifier(OnboardingAppearTransition(appeared: appeared, offset: offset, delay: delay))
    }
}
