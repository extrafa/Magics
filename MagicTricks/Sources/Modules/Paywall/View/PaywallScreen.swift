//
//  PaywallScreen.swift
//  Magic Tricks
//

import SwiftUI

private let key = L10nDomain("paywall")

struct PaywallScreen: View {
    let onDismiss: Completion

    @EnvironmentObject private var store: StoreManager
    private static let sidePadding: CGFloat = 24

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
                        VStack(alignment: .leading, spacing: 24) {
                            PaywallCardFan(cards: content.cards, cardWidth: Self.cardWidth(in: geo.size))
                            text
                        }
                        .padding(.horizontal, Self.sidePadding)
                        .padding(.vertical, 8)
                        // Centers the hand and the text on tall screens; at big text sizes it grows and scrolls instead.
                        .frame(maxWidth: .infinity, minHeight: geo.size.height, alignment: .leading)
                    }
                    .scrollBouncesOnlyWhenNeeded()
                }

                purchaseDock
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

    // MARK: Text

    // Wide screens get bigger cards; short ones (SE) shrink them so the text and the dock still fit.
    private static func cardWidth(in size: CGSize) -> CGFloat {
        min(size.width * 0.38, size.height * 0.24, 170)
    }

    private var text: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(content.headline)
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                .foregroundStyle(.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            if let effect = content.effect {
                Text(effect)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.textPrimary)
            }

            if let unlocks = content.unlocks {
                Text(coloredNames(in: unlocks))
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(notes)
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .multilineTextAlignment(.leading)
    }

    // Each trick name takes the colour of its card, so the sentence reads as the hand above it.
    private func coloredNames(in sentence: String) -> AttributedString {
        // Non-breaking spaces keep a name on one line: the sentence wraps between tricks, never inside one.
        var glued = sentence
        for trick in content.cards {
            let name = String(localized: trick.title)
            glued = glued.replacingOccurrences(of: name, with: name.replacingOccurrences(of: " ", with: "\u{00A0}"))
        }
        var result = AttributedString(glued)
        for trick in content.cards {
            let name = String(localized: trick.title).replacingOccurrences(of: " ", with: "\u{00A0}")
            if let range = result.range(of: name) {
                result[range].foregroundColor = trick.id.collectionColor
            }
        }
        return result
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

            if store.productsLoadError == nil {
                Text(key("noRenew"))
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: { Task { await store.restore() } }) {
                Group {
                    if store.phase == .restoring {
                        ProgressView()
                    } else {
                        Text(key("restore"))
                            .font(.system(.footnote, design: .rounded, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(minWidth: 44, minHeight: 44)
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

#Preview("Color Sense") {
    PaywallScreen(context: .trick(.colorSense), onDismiss: {})
        .background(Color.backgroundScreen)
        .environmentObject(StoreManager(service: PaywallPreviewStoreService()))
}

#Preview("Calculator Prediction") {
    PaywallScreen(context: .trick(.calculatorPrediction), onDismiss: {})
        .background(Color.backgroundScreen)
        .environmentObject(StoreManager(service: PaywallPreviewStoreService()))
}

#Preview("Magic Gallery") {
    PaywallScreen(context: .trick(.magicGallery), onDismiss: {})
        .background(Color.backgroundScreen)
        .environmentObject(StoreManager(service: PaywallPreviewStoreService()))
}
#endif
