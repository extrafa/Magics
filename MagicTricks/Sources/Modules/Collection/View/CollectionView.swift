//
//  CollectionView.swift
//  Magic Tricks
//
//  Created by Ross on 30/11/2025.
//

import SwiftUI

struct CollectionView: View {

    @EnvironmentObject private var flow: AppFlowCoordinator
    @EnvironmentObject private var store: StoreManager

    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(TrickCollection.tricks) { trick in
                            let isLocked = trick.id.requiresPro && !store.hasProAccess
                            TrickCardView(
                                trick: trick,
                                isLocked: isLocked,
                                onStartTap: {
                                    if isLocked {
                                        flow.openPaywall()
                                    } else {
                                        flow.open(trick: trick)
                                    }
                                },
                                onHowToTap: {
                                    if isLocked {
                                        flow.openPaywall()
                                    } else {
                                        flow.open(instruction: trick.instruction)
                                    }
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
                .environmentObject(store)
        }
        .fullScreenCover(item: $flow.activeFlow) { activeFlow in
            AppFlowCoverView(activeFlow: activeFlow)
                .environmentObject(store)
        }
    }
}

#Preview {
    CollectionView()
        .environmentObject(AppFlowCoordinator())
        .environmentObject(SettingsStore())
        .environmentObject(StoreManager())
}
