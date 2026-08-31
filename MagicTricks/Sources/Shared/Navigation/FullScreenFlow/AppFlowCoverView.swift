//
//  AppFlowCoverView.swift
//  Magic Tricks
//
//  Created by Ross on 26/01/2026.
//

import SwiftUI

struct AppFlowCoverView: View {

    let activeFlow: FullScreenFlow
    @EnvironmentObject private var flow: AppFlowCoordinator
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        switch activeFlow {
        case .trick(let trick):
            NavigationStack {
                TrickRouterView(trick: trick)
            }
            .fullScreenCover(isPresented: $flow.isPaywallOverlayPresented) {
                OBPaywallScreen(onDismiss: { flow.isPaywallOverlayPresented = false })
                    .background(Color.background)
            }
        case .paywall:
            OBPaywallScreen(onDismiss: { dismiss() })
                .background(Color.background)
        }
    }
}
