//
//  WatermarkView.swift
//  Magic Tricks
//
//  Created by Ross on 23/02/2026.
//

import SwiftUI

struct WatermarkView: View {
    @EnvironmentObject private var store: StoreManager
    @EnvironmentObject private var flow: AppFlowCoordinator
    @State private var isDismissed = false

    var body: some View {
        if !store.hasProAccess && !isDismissed && !store.isWatermarkHidden {
            HStack(spacing: 0) {
                Button { flow.presentPaywallOverlay() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Magic Tricks · Free Trial")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(Color.primaryText)
                    .padding(.leading, 10)
                    .padding(.trailing, 8)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(Color.primaryText.opacity(0.2))
                    .frame(width: 1, height: 12)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isDismissed = true
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.primaryText.opacity(0.4))
                        .padding(.leading, 8)
                        .padding(.trailing, 10)
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .background {
                if #available(iOS 26, *) {
                    Color.clear
                } else {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(Capsule().stroke(Color.grayBorder, lineWidth: 1))
                }
            }
        }
    }
}
