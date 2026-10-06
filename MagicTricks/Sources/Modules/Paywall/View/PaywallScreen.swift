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

    private let content: PaywallContent

    init(context: PaywallContext = .general, onDismiss: @escaping Completion) {
        self.content = PaywallContent(context: context)
        self.onDismiss = onDismiss
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        header
                            .staggeredAppear(appeared, step: 0)
                        PaywallShowcase(tricks: content.tricks)
                            .staggeredAppear(appeared, step: 1)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 16)
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

    // MARK: Header

    private var header: some View {
        VStack(spacing: 10) {
            if !PaywallShowcase.isCompactScreen {
                Text(key("pill"))
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(TrickPalette.proGradient))
                    .accessibilityHidden(true)
            }

            Text(content.headline)
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Text(content.subtitle)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        // At the very largest sizes the headline alone would fill the screen and push the showcase out of sight.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    // MARK: Purchase

    private var purchaseDock: some View {
        let product = store.products.first
        return VStack(spacing: 10) {
            if store.productsLoadError == nil {
                priceRow(for: product)
            }

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
        // The dock is pinned, so at accessibility sizes it would crowd out the scrolling list; cap it like system bars.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .frame(maxWidth: .infinity)
        .background(Color.backgroundScreen)
        .overlay(alignment: .top) {
            Rectangle().fill(Color.cardBorder).frame(height: 1)
        }
    }

    private func priceRow(for product: StoreProduct?) -> some View {
        let price = Text(product?.displayPrice ?? "$0.00")
            .font(.system(.title, design: .rounded, weight: .bold))
            .foregroundStyle(.textPrimary)
            .redacted(reason: product == nil ? .placeholder : [])
        let caption = Text(key("priceCaption"))
            .font(.system(.subheadline, design: .rounded))
            .foregroundStyle(.secondary)

        return ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                price
                caption
            }

            VStack(spacing: 2) {
                price
                caption
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHidden(product == nil)
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
                title: String(localized: key("cta")),
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
