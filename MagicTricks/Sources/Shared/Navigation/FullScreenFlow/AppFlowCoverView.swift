//
//  AppFlowCoverView.swift
//  Magic Tricks
//
//  Created by Ross on 26/01/2026.
//

import SwiftUI

struct AppFlowCoverView: View {

    let activeFlow: FullScreenFlow

    var body: some View {
        NavigationStack {
            switch activeFlow {
            case .trick(let trick):
                TrickRouterView(trick: trick)
            }
        }
    }
}
