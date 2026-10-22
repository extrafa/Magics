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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundScreen.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 16) {
                        if dynamicTypeSize.isAccessibilitySize {
                            wrappingTitle
                        }
                        ForEach(TrickCollection.tricks) { trick in
                            let isLocked = store.showsLock(for: trick.id)
                            TrickCardView(
                                trick: trick,
                                isLocked: isLocked,
                                onStartTap: { whenAccessKnown { flow.openStartFlow(for: trick) } },
                                onHowToTap: { whenAccessKnown { flow.open(instruction: trick) } }
                            )
                        }
                    }
                    .padding(16)
                }
                .scrollIndicators(.hidden)
            }
            // The system large title never wraps and gets cut ("Centro de Tr...") at the biggest sizes, and an inline one
            // would sit under the Pro button; there the title becomes a wrapping heading in the list instead.
            .navigationTitle(dynamicTypeSize.isAccessibilitySize ? "" : String(localized: "collection.title"))
            .navigationBarTitleDisplayMode(dynamicTypeSize.isAccessibilitySize ? .inline : .large)
            .navigationDestination(isPresented: $showSettings) {
                SettingsScreen()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel(String(localized: "settings.title"))
                }
            }
        }
        .overlay(alignment: .topLeading) {
            if store.showsFreeTier {
                ProUpgradeButton(action: { flow.openPaywall() })
                    .padding(.leading, 20)
                    .padding(.top, 4)
                    .opacity(showSettings ? 0 : 1)
                    .scaleEffect(showSettings ? 0.85 : 1, anchor: .leading)
                    .animation(.spring(response: 0.35, dampingFraction: 0.78), value: showSettings)
            }
        }
        .sheet(item: $flow.activeSheet, onDismiss: flow.sheetDidDismiss) { activeSheet in
            AppSheetView(activeSheet: activeSheet)
                .presentationDragIndicator(.visible)
                .environmentObject(store)
                .environmentObject(flow)
        }
        .fullScreenCover(item: $flow.activeFlow) { activeFlow in
            AppFlowCoverView(activeFlow: activeFlow)
                .environmentObject(store)
                .environmentObject(flow)
        }
    }

    private var wrappingTitle: some View {
        Text(String(localized: "collection.title"))
            .font(.largeTitle.bold())
            .foregroundStyle(.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }

    // A tap right after launch waits for the purchase check, so it neither lets a free user in nor shows an owner the paywall.
    private func whenAccessKnown(_ action: @escaping Completion) {
        Task {
            await store.waitForResolvedAccess()
            action()
        }
    }
}

#Preview {
    let store = StoreManager()
    CollectionView()
        .environmentObject(AppFlowCoordinator(store: store))
        .environmentObject(SettingsStore())
        .environmentObject(store)
}
