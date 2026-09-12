//
//  OBPaywallScreen.swift
//  Magic Tricks
//
//  Created by Ross on 28/03/2026.
//

import SwiftUI

struct OBPaywallScreen: View {
    let onDismiss: () -> Void

    @EnvironmentObject private var store: StoreManager
    @State private var appeared = false
    @State private var topInset: CGFloat = 44

    private struct Benefit {
        let icon: String
        let color: Color
        let title: String
        let detail: String
    }

    private typealias Palette = TrickPalette.Collection

    private let benefits: [Benefit] = [
        Benefit(
            icon: "photo.on.rectangle.angled",
            color: Palette.magicGallery,
            title: String.paywall("benefit.magicGallery"),
            detail: String.paywall("benefit.magicGallery.detail")
        ),
        Benefit(
            icon: "ipad",
            color: Palette.calculatorPrediction,
            title: String.paywall("benefit.calculatorPrediction"),
            detail: String.paywall("benefit.calculatorPrediction.detail")
        ),
        Benefit(
            icon: "paintpalette",
            color: Palette.colorSense,
            title: String.paywall("benefit.colorSense"),
            detail: String.paywall("benefit.colorSense.detail")
        ),
        Benefit(
            icon: "stopwatch.fill",
            color: Palette.timeControl,
            title: String.paywall("benefit.timeControl"),
            detail: String.paywall("benefit.timeControl.detail")
        ),
        Benefit(
            icon: "sparkles",
            color: TrickPalette.accentPrimary,
            title: String.paywall("benefit.noWatermark"),
            detail: String.paywall("benefit.noWatermark.detail")
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            closeButton

            GeometryReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)

                        heroIcon
                            .padding(.bottom, 16)

                        titleBlock
                            .padding(.horizontal, 24)
                            .padding(.bottom, 24)
                            .padding(.top, 4)

                        benefitsList
                            .padding(.horizontal, 24)
                    }
                    .frame(minWidth: proxy.size.width, minHeight: proxy.size.height)
                }
            }

            bottomBlock
                .padding(.top, 28)
                .padding(.bottom, 40)
        }
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: TopInsetKey.self, value: proxy.safeAreaInsets.top)
            }
            .ignoresSafeArea()
        )
        .onPreferenceChange(TopInsetKey.self) { value in
            if value > 0 { topInset = value }
        }
        .onAppear {
            Task { @MainActor in
                try? await Task.sleep(milliseconds: 240)
                appeared = true
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
        HStack {
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color.primary.opacity(0.08)))
            }
            .accessibilityLabel(String(localized: "common.close"))
        }
        .padding(.horizontal, 20)
        .padding(.top, topInset + 8)
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.2).delay(0.5), value: appeared)
    }

    // MARK: Hero

    @State private var heroPulse = false

    private var heroIcon: some View {
        ZStack {
            Circle()
                .stroke(Color.primaryText.opacity(0.1), lineWidth: 1)
                .frame(width: 136, height: 136)

            ForEach(0..<8, id: \.self) { i in
                HeroSparkle(index: i)
            }

            Circle()
                .fill(Color.primaryText.opacity(heroPulse ? 0.13 : 0.07))
                .frame(
                    width: heroPulse ? 104 : 98,
                    height: heroPulse ? 104 : 98
                )
                .animation(
                    .easeInOut(duration: 2.6).repeatForever(autoreverses: true),
                    value: heroPulse
                )

            Image(systemName: "wand.and.stars")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(.primaryText)
        }
        .scaleEffect(appeared ? 1 : 0.65)
        .opacity(appeared ? 1 : 0)
        .animation(.onboardingAppear.delay(0.06), value: appeared)
        .onAppear { heroPulse = true }
    }

    // MARK: Title

    private var titleBlock: some View {
        VStack(spacing: 8) {
            Text(String.paywall("title"))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primaryText)
                .onboardingAppear(appeared, offset: 14, delay: 0.2)

            Text(String.paywall("subtitle"))
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)
                .onboardingAppear(appeared, offset: 10, delay: 0.27)
        }
        .multilineTextAlignment(.center)
    }

    // MARK: Benefits

    private var benefitsList: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(benefits.indices, id: \.self) { i in
                let benefit = benefits[i]
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(benefit.color.opacity(0.13))
                            .frame(width: 42, height: 42)
                        Image(systemName: benefit.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(benefit.color)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(benefit.title)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primaryText)
                        Text(benefit.detail)
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                .onboardingAppear(appeared, offset: 10, delay: 0.34 + Double(i) * 0.07)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Bottom

    private var bottomBlock: some View {
        let product = store.products.first
        return VStack(spacing: 12) {
            priceLabel(for: product)

            purchaseSection(for: product)

            Button(action: { Task { await store.restore() } }) {
                if store.phase == .restoring {
                    ProgressView()
                        .padding(.vertical, 8)
                } else {
                    Text(String.paywall("restore"))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }
            }
            .disabled(store.phase != .idle)

            HStack(spacing: 16) {
                Link(String.paywall("terms"), destination: AppConfig.termsOfUseURL)
                Text(String(localized: "common.dotSeparator"))
                Link(String.paywall("privacy"), destination: AppConfig.privacyPolicyURL)
            }
            .font(.system(size: 11, weight: .regular, design: .rounded))
            .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .onboardingAppear(appeared, offset: 16, delay: 0.58 + Double(benefits.count - 1) * 0.08)
    }

    // MARK: Purchase

    @ViewBuilder
    private func purchaseSection(for product: StoreProduct?) -> some View {
        if let productsLoadError = store.productsLoadError {
            VStack(spacing: 10) {
                Text(productsLoadError)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: 300)

                OnboardingCTAButton(
                    title: String.paywall("retry"),
                    isLoading: store.phase == .loadingProducts,
                    action: { Task { await store.retryLoadProducts() } }
                )
                .padding(.horizontal, 24)
            }
        } else {
            OnboardingCTAButton(
                title: String.paywall("cta"),
                isEnabled: product != nil && store.phase != .restoring,
                isLoading: store.phase == .purchasing || store.phase == .loadingProducts,
                action: {
                    guard let product else { return }
                    Task { await store.purchase(productID: product.id) }
                }
            )
            .padding(.horizontal, 24)
        }
    }

    // MARK: Price

    @ViewBuilder
    private func priceLabel(for product: StoreProduct?) -> some View {
        if let price = product?.displayPrice {
            VStack(spacing: 6) {
                purchaseBadge

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(price)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.primaryText)

                    Text(String.paywall("period"))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var purchaseBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 11))
                .accessibilityHidden(true)
            Text(String.paywall("onetime"))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(TrickPalette.accentPrimary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(TrickPalette.accentPrimary.opacity(0.12)))
    }
}


private extension String {
    static func paywall(_ key: String) -> String {
        NSLocalizedString("onboarding.paywall.\(key)", comment: "")
    }
}

private struct TopInsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct HeroSparkle: View {
    let index: Int

    private static let sizes:  [CGFloat] = [8, 4, 9, 4, 7, 4, 9, 4]
    private static let delays: [Double]  = [0, 0.55, 0.25, 0.80, 0.45, 0.10, 0.65, 0.35]

    private var angle:    Double  { Double(index) / 8.0 * 2 * .pi - .pi / 2 }
    private var starSize: CGFloat { Self.sizes[index] }
    private var duration: Double  { 1.4 + Double(index % 3) * 0.4 }
    private var delay:    Double  { Self.delays[index] }

    @State private var active = false

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: starSize, weight: .bold))
            .foregroundStyle(Color.primaryText)
            .opacity(active ? 0.7 : 0.08)
            .scaleEffect(active ? 1.1 : 0.5)
            .offset(x: cos(angle) * 68, y: sin(angle) * 68)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    active = true
                }
            }
    }
}

#Preview {
    OBPaywallScreen(onDismiss: {})
        .background(Color.background)
        .environmentObject(StoreManager())
}
