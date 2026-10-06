//
//  PaywallScreen.swift
//  Magic Tricks
//

import SwiftUI

private let key = L10nDomain("paywall")

struct PaywallScreen: View {
    let onDismiss: Completion

    @EnvironmentObject private var store: StoreManager
    @State private var appeared = false
    @ScaledMetric(relativeTo: .largeTitle) private var priceSize: CGFloat = 72

    private let content: PaywallContent

    init(context: PaywallContext = .general, onDismiss: @escaping Completion) {
        self.content = PaywallContent(context: context)
        self.onDismiss = onDismiss
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                GeometryReader { geo in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 28) {
                            hero
                                .staggeredAppear(appeared, step: 0)
                            details
                                .staggeredAppear(appeared, step: 1)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        // Centers the poster on tall screens; at big text sizes it grows and scrolls instead.
                        .frame(maxWidth: .infinity, minHeight: geo.size.height)
                    }
                    .scrollBouncesOnlyWhenNeeded()
                }

                purchaseDock
                    .staggeredAppear(appeared, step: 2)
            }
            .background { Color.backgroundScreen.ignoresSafeArea() }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    closeButton
                }
            }
        }
        .task {
            await store.reloadProductsIfNeeded()
        }
        .task {
            // Let the cover finish presenting before the staggered entrance starts.
            try? await Task.sleep(milliseconds: 200)
            appeared = true
        }
        .onChange(of: store.hasProAccess) { _ in
            if store.hasProAccess { onDismiss() }
        }
        .tint(.primary)
        .storeErrorAlert(store)
    }

    // MARK: Close

    private var closeButton: some View {
        Button(action: onDismiss) {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background {
                    if #available(iOS 26, *) {
                        Color.clear
                    } else {
                        Circle().fill(Color.primary.opacity(0.08))
                    }
                }
        }
        .accessibilityLabel(String(localized: "common.close"))
    }

    // MARK: Hero

    private var hero: some View {
        VStack(spacing: 20) {
            Text(content.headline)
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(.textPrimary)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            if store.productsLoadError == nil {
                priceBlock(for: store.products.first)
            }

            PaywallCoinTrail()
        }
        // At the very largest sizes the headline and caption alone would push the coins and the rest out of sight.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    // The price is the biggest thing on the screen: it's the whole deal.
    private func priceBlock(for product: StoreProduct?) -> some View {
        VStack(spacing: 4) {
            Text(product?.displayPrice ?? "$0.00")
                .font(.system(size: priceSize, weight: .heavy, design: .rounded))
                .foregroundStyle(.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .redacted(reason: product == nil ? .placeholder : [])

            Text(key("priceCaption"))
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
        .accessibilityHidden(product == nil)
    }

    // MARK: Details

    private var details: some View {
        VStack(spacing: 10) {
            if let unlocks = content.unlocks {
                Text(unlocks)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(.textPrimary)
            }

            Text(notes)
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
    }

    private var notes: String {
        [content.freeNote, String(localized: key("watermarkNote"))]
            .compactMap { $0 }
            .joined(separator: " ")
    }

    // MARK: Purchase

    private var purchaseDock: some View {
        let product = store.products.first
        return VStack(spacing: 10) {
            purchaseSection(for: product)

            Button(action: { Task { await store.restore() } }) {
                if store.phase == .restoring {
                    ProgressView()
                        .padding(.vertical, 8)
                } else {
                    Text(key("restore"))
                        .font(.system(.footnote, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }
            }
            .disabled(store.phase != .idle)

            HStack(spacing: 16) {
                Link(String(localized: key("terms")), destination: AppConfig.termsOfUseURL)
                Text(String(localized: "common.dotSeparator"))
                Link(String(localized: key("privacy")), destination: AppConfig.privacyPolicyURL)
            }
            .font(.system(.caption2, design: .rounded))
            .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 14)
        // The dock is pinned, so at accessibility sizes it would crowd out the scrolling poster; cap it like system bars.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .frame(maxWidth: .infinity)
        .background(Color.backgroundScreen)
        .overlay(alignment: .top) {
            Rectangle().fill(Color.cardBorder).frame(height: 1)
        }
    }

    @ViewBuilder
    private func purchaseSection(for product: StoreProduct?) -> some View {
        if let productsLoadError = store.productsLoadError {
            VStack(spacing: 10) {
                Text(productsLoadError)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                OnboardingCTAButton(
                    title: String(localized: key("retry")),
                    isLoading: store.phase == .loadingProducts,
                    action: { Task { await store.retryLoadProducts() } }
                )
            }
        } else {
            OnboardingCTAButton(
                title: ctaTitle(for: product),
                isEnabled: product != nil && store.phase != .restoring,
                isLoading: store.phase == .purchasing || store.phase == .loadingProducts,
                action: {
                    guard let product else { return }
                    Task { await store.purchase(productID: product.id) }
                }
            )
            .shimmer(
                in: RoundedRectangle(cornerRadius: 16, style: .continuous),
                isActive: product != nil && store.phase == .idle,
                highlight: Color.backgroundScreen.opacity(0.22),
                blend: .normal
            )
        }
    }

    // The button repeats the deal at the moment of paying: how much, and that it's once.
    private func ctaTitle(for product: StoreProduct?) -> String {
        guard let product else { return String(localized: key("cta")) }
        return String.localizedStringWithFormat(String(localized: key("ctaPrice")), product.displayPrice)
    }
}

private extension View {
    @ViewBuilder
    func scrollBouncesOnlyWhenNeeded() -> some View {
        if #available(iOS 16.4, *) {
            scrollBounceBehavior(.basedOnSize)
        } else {
            self
        }
    }
}

// MARK: - Entrance

private struct StaggeredAppear: ViewModifier {
    let appeared: Bool
    let step: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.onboardingAppear(appeared, offset: 12, delay: Double(step) * 0.06)
        }
    }
}

private extension View {
    func staggeredAppear(_ appeared: Bool, step: Int) -> some View {
        modifier(StaggeredAppear(appeared: appeared, step: step))
    }
}

#if DEBUG
@MainActor
final class PaywallPreviewStoreService: StoreServicing {
    enum Mode {
        case loaded
        case loadFails
        case neverLoads
    }

    private let mode: Mode

    init(mode: Mode = .loaded) {
        self.mode = mode
    }

    func loadProducts(for productIDs: [String]) async throws -> [StoreProduct] {
        switch mode {
        case .loaded:
            return [StoreProduct(id: "magic_lifetime", displayName: "Lifetime", displayPrice: "$9.99")]
        case .loadFails:
            throw URLError(.notConnectedToInternet)
        case .neverLoads:
            try await Task.sleep(seconds: 3600)
            return []
        }
    }

    func purchase(productID: String) async throws -> StorePurchaseResult { .userCancelled }
    func currentEntitlementProductIDs() -> AsyncStream<String> { AsyncStream { $0.finish() } }
    func transactionUpdateProductIDs() -> AsyncStream<String> { AsyncStream { _ in } }
    func sync() async throws {}
}

#Preview("General") {
    PaywallScreen(context: .general, onDismiss: {})
        .background(Color.backgroundScreen)
        .environmentObject(StoreManager(service: PaywallPreviewStoreService()))
}

#Preview("Phantom Draw") {
    PaywallScreen(context: .trick(.phantomDraw), onDismiss: {})
        .background(Color.backgroundScreen)
        .environmentObject(StoreManager(service: PaywallPreviewStoreService()))
}

#Preview("Store error") {
    PaywallScreen(context: .general, onDismiss: {})
        .background(Color.backgroundScreen)
        .environmentObject(StoreManager(service: PaywallPreviewStoreService(mode: .loadFails)))
}

#Preview("Loading price") {
    PaywallScreen(context: .general, onDismiss: {})
        .background(Color.backgroundScreen)
        .environmentObject(StoreManager(service: PaywallPreviewStoreService(mode: .neverLoads)))
}

#Preview("Time Control") {
    PaywallScreen(context: .trick(.timeControl), onDismiss: {})
        .background(Color.backgroundScreen)
        .environmentObject(StoreManager(service: PaywallPreviewStoreService()))
}
#endif
