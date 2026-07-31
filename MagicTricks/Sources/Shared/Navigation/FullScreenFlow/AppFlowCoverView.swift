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
            NavigationStack {
                TrickRouterView(trick: trick)
            }
        case .paywall:
            ZStack(alignment: .topTrailing) {
                OBPaywallScreen(onDismiss: { dismiss() })
                    .background(Color.background)

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color.grayCard))
                }
                .padding(.top, 56)
                .padding(.trailing, 20)
            }
        }
    }
}
