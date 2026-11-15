//
//  HapticsUnavailableNotice.swift
//  Magic Tricks
//

import CoreHaptics
import SwiftUI

// Shows nothing on iPhones; explains why nothing vibrates on devices without a haptic engine (iPad, Simulator).
struct HapticsUnavailableNotice: View {

    // The TestFlight toggle that lets a tester on an iPad hide the badge.
    static let testerHiddenKey = "dev.hapticsNoticeHidden"

    private static let isUnavailable = !CHHapticEngine.capabilitiesForHardware().supportsHaptics

    @AppStorage(testerHiddenKey) private var isHiddenByTester = false

    // The toggle does nothing in a release build, whatever the stored flag says.
    static func shouldShow(isUnavailable: Bool, isInternalBuild: Bool, isHiddenByTester: Bool) -> Bool {
        isUnavailable && !(isInternalBuild && isHiddenByTester)
    }

    var body: some View {
        if Self.shouldShow(
            isUnavailable: Self.isUnavailable,
            isInternalBuild: AppBuildEnvironment.isInternalBuild,
            isHiddenByTester: isHiddenByTester
        ) {
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
