//
//  PaywallScreen.swift
//  Magic Tricks
//

import SwiftUI

private let key = L10nDomain("paywall")

struct PaywallScreen: View {
    let onDismiss: Completion

    @EnvironmentObject private var store: StoreManager

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
                        trickList
                        Text(key("footnote"))
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 16)
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

    // MARK: Header

    private var header: some View {
        VStack(spacing: 12) {
            Text(key("pill"))
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Capsule().fill(TrickPalette.proGradient))

            Text(content.headline)
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(.textPrimary)

            Text(content.subtitle)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
    }

    // MARK: Tricks

    @ViewBuilder
    private var trickList: some View {
        if let highlighted = content.highlighted {
            VStack(spacing: 7) {
                PaywallTrickRow(item: highlighted, style: .highlighted)

                Text(key("alsoIncluded"))
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                    .padding(.top, 4)
                    .accessibilityAddTraits(.isHeader)

                ForEach(content.others) { item in
                    PaywallTrickRow(item: item, style: .compact)
                }
            }
        } else {
            VStack(spacing: 7) {
                ForEach(content.tricks) { item in
                    PaywallTrickRow(item: item, style: .regular)
                }
            }
        }
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
        .frame(maxWidth: .infinity)
        .background(Color.backgroundScreen)
        .overlay(alignment: .top) {
            Rectangle().fill(Color.cardBorder).frame(height: 1)
        }
    }

    private func priceRow(for product: StoreProduct?) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(product?.displayPrice ?? "$0.00")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(.textPrimary)
                .redacted(reason: product == nil ? .placeholder : [])

            Text(key("priceCaption"))
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
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
                title: String(localized: key("cta")),
                isEnabled: product != nil && store.phase != .restoring,
                isLoading: store.phase == .purchasing || store.phase == .loadingProducts,
                action: {
                    guard let product else { return }
                    Task { await store.purchase(productID: product.id) }
                }
            )
        }
    }
}

// MARK: - Trick row

private struct PaywallTrickRow: View {
    enum Style {
        case regular
        case highlighted
        case compact
    }

    let item: PaywallTrick
    let style: Style

    private var color: Color { item.trick.id.collectionColor }

    private var chipSize: CGFloat {
        switch style {
        case .regular: 40
        case .highlighted: 46
        case .compact: 30
        }
    }

    private var verticalPadding: CGFloat {
        switch style {
        case .regular: 9
        case .highlighted: 13
        case .compact: 6
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: style == .compact ? 8 : 10, style: .continuous)
                    .fill(color.opacity(style == .highlighted ? 0.2 : 0.14))
                    .frame(width: chipSize, height: chipSize)
                Image(systemName: item.trick.image.rawValue)
                    .font(.system(size: style == .compact ? 14 : style == .highlighted ? 21 : 18, weight: .semibold))
                    .foregroundStyle(color)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.trick.title)
                    .font(.system(style == .highlighted ? .body : .subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.textPrimary)
                if style != .compact {
                    Text(item.effect)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: style == .highlighted ? "lock.open.fill" : "checkmark.circle.fill")
                .font(style == .highlighted ? .body : .callout)
                .foregroundStyle(color)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, verticalPadding)
        .cardSurface(cornerRadius: 16)
        .overlay {
            if style == .highlighted {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(color.opacity(0.08))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(color, lineWidth: 1.5)
                    }
                    .allowsHitTesting(false)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
@MainActor
final class PaywallPreviewStoreService: StoreServicing {
    func loadProducts(for productIDs: [String]) async throws -> [StoreProduct] {
        [StoreProduct(id: "magic_lifetime", displayName: "Lifetime", displayPrice: "$9.99")]
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

#Preview("Time Control") {
    PaywallScreen(context: .trick(.timeControl), onDismiss: {})
        .background(Color.backgroundScreen)
        .environmentObject(StoreManager(service: PaywallPreviewStoreService()))
}
#endif
