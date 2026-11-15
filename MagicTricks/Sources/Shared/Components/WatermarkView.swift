//
//  WatermarkView.swift
//  Magic Tricks
//
//  Created by Ross on 23/02/2026.
//

import SwiftUI

struct WatermarkView: View {
    // In the navigation bar the system draws the capsule on iOS 26; floating over a screen, the view draws it itself.
    var isFloating = false

    @EnvironmentObject private var store: StoreManager
    @EnvironmentObject private var flow: AppFlowCoordinator
    @State private var isDismissed = false

    var body: some View {
        if Self.canShow(on: store) && !isDismissed {
            HStack(spacing: 0) {
                Button { flow.presentPaywallOverlay() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: isFloating ? 14 : 11, weight: .semibold))
                            .accessibilityHidden(true)
                        // "Free Trial" names the free tier, there is no trial period; kept on purpose (monetisation decision).
                        Text(String(localized: "watermark.freeTrialBadge"))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(Color.textPrimary)
                    .padding(.leading, 10)
                    .padding(.trailing, 8)
                    .padding(.vertical, 6)
                    .frame(minHeight: isFloating ? Self.floatingHeight : nil)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(Color.textPrimary.opacity(0.2))
                    .frame(width: 1, height: 12)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isDismissed = true
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: isFloating ? 11.5 : 9, weight: .bold))
                        .foregroundStyle(Color.textPrimary.opacity(0.4))
                        .padding(.leading, 8)
                        .padding(.trailing, 10)
                        .padding(.vertical, 6)
                        .frame(minHeight: isFloating ? Self.floatingHeight : nil)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "common.close"))
            }
            // In the navigation bar the system makes the capsule 44 pt tall with room around the content; floating, it is sized the same,
            // and both buttons reach the full height.
            .padding(.horizontal, isFloating ? 4 : 0)
            .background { capsuleBackground }
        }
    }

    // As tall as the system's capsule in the navigation bar: the watermark has always been this size.
    static let floatingHeight: CGFloat = 44

    @ViewBuilder
    private var capsuleBackground: some View {
        if #available(iOS 26, *) {
            if isFloating {
                Color.clear.glassEffect(.regular, in: Capsule())
            } else {
                Color.clear
            }
        } else {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().stroke(Color.cardBorder, lineWidth: 1))
        }
    }

    // Whether the watermark can show at all, whatever the person did with it: the screens that float it keep its place free.
    static func canShow(on store: StoreManager) -> Bool {
        store.showsFreeTier && !store.isWatermarkSuppressed
    }
}
