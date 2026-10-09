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

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : offset)
            .animation(.onboardingAppear.delay(delay), value: appeared)
    }
}

extension View {
    func onboardingAppear(_ appeared: Bool, offset: CGFloat = 14, delay: Double = 0) -> some View {
        modifier(OnboardingAppearTransition(appeared: appeared, offset: offset, delay: delay))
    }
}
