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
        NavigationStackCompat {
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

                NavigationLink(destination: SettingsScreen(), isActive: $showSettings) {
                    EmptyView()
                }
                .hidden()
            }
            .navigationTitle(String(localized: "collection.title"))
            .navigationBarTitleDisplayMode(.large)
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

// MARK: - ProUpgradeButton

private struct ProUpgradeButton: View {
    let action: () -> Void
    @State private var shimmer = false

    var body: some View {
        Button(action: action) {
            Text("Get Pro")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background { capsule }
        }
        .task { await shimmerLoop() }
    }

    private var capsule: some View {
        Capsule()
            .fill(LinearGradient(
                colors: [Color(red: 1.0, green: 0.58, blue: 0.08), Color(red: 1.0, green: 0.28, blue: 0.42)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .overlay(shimmerLayer)
    }

    private var shimmerLayer: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [.clear, .white.opacity(0.38), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geo.size.width * 0.5)
            .offset(x: shimmer ? geo.size.width * 1.2 : -geo.size.width * 0.5)
        }
        .clipShape(Capsule())
        .blendMode(.screen)
        .allowsHitTesting(false)
    }

    private func shimmerLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(seconds: 2.5)
            withAnimation(.easeInOut(duration: 0.75)) { shimmer = true }
            try? await Task.sleep(milliseconds: 950)
            shimmer = false
        }
    }
}

#Preview {
    CollectionView()
        .environmentObject(AppFlowCoordinator())
        .environmentObject(SettingsStore())
        .environmentObject(StoreManager())
}
