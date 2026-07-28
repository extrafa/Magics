//
//  CollectionView.swift
//  Magic Tricks
//
//  Created by Ross on 30/11/2025.
//

import SwiftUI

struct CollectionView: View {

    @EnvironmentObject private var flow: AppFlowCoordinator

    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(TrickCollection.tricks) { trick in
                            TrickCardView(
                                trick: trick,
                                onStartTap: {
                                    flow.open(trick: trick)
                                },
                                onHowToTap: {
                                    flow.open(instruction: trick.instruction)
                                }
                            )
                        }
                    }
                    .padding(16)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle(String(localized: "collection.title"))
            .navigationBarTitleDisplayMode(.large)
            .fontDesign(.rounded)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsScreen()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
        .sheet(item: $flow.activeSheet) { activeSheet in
            AppSheetView(activeSheet: activeSheet)
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(item: $flow.activeFlow) { activeFlow in
            AppFlowCoverView(activeFlow: activeFlow)
        }
    }
}

#Preview {
    CollectionView()
        .environmentObject(AppFlowCoordinator())
        .environmentObject(SettingsStore())
}
