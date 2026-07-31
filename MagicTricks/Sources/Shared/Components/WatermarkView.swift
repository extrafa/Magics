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
            Text("Magic Tricks")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.primaryText)
                .opacity(0.72)
                .shadow(color: Color.primaryText.opacity(0.25), radius: 8, x: 0, y: 2)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .onTapGesture { showPaywall = true }
                .allowsHitTesting(true)
                .fullScreenCover(isPresented: $showPaywall) {
                    AppFlowCoverView(activeFlow: .paywall)
                        .environmentObject(store)
                }
        }
    }
}
