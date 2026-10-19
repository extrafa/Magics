//
//  PaywallPurchaseDock.swift
//  Magic Tricks
//

import SwiftUI

private let key = L10nDomain("paywall")

// The pinned panel under the paywall text: the price button, Restore and the legal links.
struct PaywallPurchaseDock: View {
    @EnvironmentObject private var store: StoreManager
    @Binding var storeAlert: StoreAlert?

    var body: some View {
        let product = store.products.first
        return VStack(spacing: 10) {
            purchaseSection(for: product)

            if store.productsLoadError == nil {
                Text(key("noRenew"))
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: { Task { storeAlert = await store.restore() } }) {
                Group {
                    if store.isRestoring {
                        ProgressView()
                    } else {
                        Text(key("restore"))
                            .font(.system(.footnote, design: .rounded, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(minWidth: 44, minHeight: 44)
            }
            .disabled(store.isTransacting)

            HStack(spacing: 16) {
                // 44 pt tall, so the small legal text is still easy to hit.
                Link(String(localized: key("terms")), destination: AppConfig.termsOfUseURL)
                    .frame(minHeight: 44)
                Text(String(localized: "common.dotSeparator"))
                Link(String(localized: key("privacy")), destination: AppConfig.privacyPolicyURL)
                    .frame(minHeight: 44)
            }
            .font(.system(.caption2, design: .rounded))
            .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 2)
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
                    isLoading: store.isLoadingProducts,
                    action: { Task { await store.retryLoadProducts() } }
                )
            }
        } else {
            OnboardingCTAButton(
                title: ctaTitle(for: product),
                isEnabled: product != nil && !store.isRestoring,
                isLoading: store.isPurchasing || store.isLoadingProducts,
                action: {
                    guard let product else { return }
                    Task { storeAlert = await store.purchase(productID: product.id) }
                }
            )
            .shimmer(
                in: RoundedRectangle(cornerRadius: 16, style: .continuous),
                isActive: product != nil && !store.isTransacting && !store.isLoadingProducts,
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
