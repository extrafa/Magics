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
                TrickRouterView(type: trick.id)
            }
            .fullScreenCover(isPresented: $flow.isPaywallOverlayPresented) {
                OnboardingPaywallScreen(onDismiss: flow.dismissPaywallOverlay)
                    .background(Color.backgroundScreen)
            }
        case .paywall:
            OnboardingPaywallScreen(onDismiss: { dismiss() })
                .background(Color.backgroundScreen)
        }
    }
}
