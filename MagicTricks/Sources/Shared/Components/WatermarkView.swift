//
//  WatermarkView.swift
//  Magic Tricks
//
//  Created by Ross on 23/02/2026.
//

import SwiftUI

struct WatermarkView: View {
    @EnvironmentObject private var store: StoreManager
    @State private var showPaywall = false

    var body: some View {
        if !store.hasProAccess {
            Button { showPaywall = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Magic Tricks · Free Trial")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                    Rectangle()
                        .fill(Color.primaryText.opacity(0.2))
                        .frame(width: 1, height: 12)
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.primaryText.opacity(0.4))
                }
                .foregroundStyle(Color.primaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
            .fullScreenCover(isPresented: $showPaywall) {
                AppFlowCoverView(activeFlow: .paywall)
                    .environmentObject(store)
            }
        }
    }
}
