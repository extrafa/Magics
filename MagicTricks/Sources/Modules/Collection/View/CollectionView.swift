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
    @State private var showSettings = false
    @State private var previousActiveFlow: FullScreenFlow? = nil

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
                                        flow.openStartFlow(for: trick)
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
                .hideScrollIndicators()
            }
            .navigationTitle(String(localized: "collection.title"))
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(isPresented: $showSettings) {
                SettingsScreen()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
        .overlay(alignment: .topLeading) {
            if !store.hasProAccess {
                ProUpgradeButton(action: flow.openPaywall)
                    .padding(.leading, 20)
                    .padding(.top, 4)
                    .opacity(showSettings ? 0 : 1)
                    .scaleEffect(showSettings ? 0.85 : 1, anchor: .leading)
                    .animation(.spring(response: 0.35, dampingFraction: 0.78), value: showSettings)
            }
        }
        .sheet(item: $flow.activeSheet) { activeSheet in
            AppSheetView(activeSheet: activeSheet)
                .withPresentationDragIndicator()
                .environmentObject(store)
                .environmentObject(flow)
        }
        .fullScreenCover(item: $flow.activeFlow) { activeFlow in
            AppFlowCoverView(activeFlow: activeFlow)
                .environmentObject(store)
        }
        .onChange(of: flow.activeFlow) { newValue in
            if case .trick = previousActiveFlow, newValue == nil {
                flow.recordTrickClose()
            }
            previousActiveFlow = newValue
        }
    }
}

#Preview {
    CollectionView()
        .environmentObject(AppFlowCoordinator())
        .environmentObject(SettingsStore())
        .environmentObject(StoreManager())
}
