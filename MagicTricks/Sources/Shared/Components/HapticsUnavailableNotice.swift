//
//  HapticsUnavailableNotice.swift
//  Magic Tricks
//

import CoreHaptics
import SwiftUI

// Shows nothing on iPhones; explains why nothing vibrates on devices without a haptic engine (iPad, Simulator).
struct HapticsUnavailableNotice: View {

    private static let isUnavailable = !CHHapticEngine.capabilitiesForHardware().supportsHaptics

    var body: some View {
        if Self.isUnavailable {
            HStack(spacing: 8) {
                Image(systemName: "iphone.slash")
                Text(String(localized: "haptics.unavailable.notice"))
                    .multilineTextAlignment(.leading)
            }
            .font(.system(.footnote, design: .rounded, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.8), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
            }
            .accessibilityElement(children: .combine)
        }
    }
}

extension View {
    // For full-screen trick screens: floats the notice over the top without taking touches.
    func hapticsUnavailableNoticeOverlay() -> some View {
        overlay(alignment: .top) {
            HapticsUnavailableNotice()
                .padding(.top, 8)
                .padding(.horizontal, 16)
                .allowsHitTesting(false)
        }
    }
}
