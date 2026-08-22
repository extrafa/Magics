//
//  AppFlowCoverView.swift
//  Magic Tricks
//
//  Created by Ross on 26/01/2026.
//

import SwiftUI

struct AppFlowCoverView: View {

    let activeFlow: FullScreenFlow
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        switch activeFlow {
        case .trick(let trick):
            NavigationStackCompat {
                TrickRouterView(trick: trick)
            }
        case .paywall:
            OBPaywallScreen(onDismiss: { dismiss() })
                .background(Color.background)
        }
    }
}
