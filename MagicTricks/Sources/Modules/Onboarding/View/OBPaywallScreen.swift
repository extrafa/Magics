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

    private struct Benefit {
        let icon: String
        let color: Color
        let title: String
        let detail: String
    }

    private let benefits: [Benefit] = [
        Benefit(icon: "photo.on.rectangle.angled", color: TrickPalette.Collection.magicGallery,         title: String(localized: "onboarding.paywall.benefit.magicGallery"),         detail: String(localized: "onboarding.paywall.benefit.magicGallery.detail")),
        Benefit(icon: "ipad",                      color: TrickPalette.Collection.calculatorPrediction, title: String(localized: "onboarding.paywall.benefit.calculatorPrediction"), detail: String(localized: "onboarding.paywall.benefit.calculatorPrediction.detail")),
        Benefit(icon: "paintpalette",              color: TrickPalette.Collection.colorSense,           title: String(localized: "onboarding.paywall.benefit.colorSense"),           detail: String(localized: "onboarding.paywall.benefit.colorSense.detail")),
        Benefit(icon: "stopwatch.fill",            color: TrickPalette.Collection.timeControl,          title: String(localized: "onboarding.paywall.benefit.timeControl"),          detail: String(localized: "onboarding.paywall.benefit.timeControl.detail")),
        Benefit(icon: "sparkles",                  color: Color("collectionMindPattern"),               title: String(localized: "onboarding.paywall.benefit.noWatermark"),         detail: String(localized: "onboarding.paywall.benefit.noWatermark.detail")),
    ]

    var body: some View {
        VStack(spacing: 0) {
            closeButton

            Spacer()

            heroIcon
                .padding(.bottom, 16)

            titleBlock
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .padding(.top, 4)

            benefitsList
                .padding(.horizontal, 24)

            Spacer()

            bottomBlock
                .padding(.bottom, 40)
        }
        .onAppear {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(240))
                appeared = true
            }
        }
        .onChange(of: store.hasProAccess) {
            if store.hasProAccess { onDismiss() }
        }
        .fontDesign(.rounded)
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
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.2).delay(0.5), value: appeared)
    }

    // MARK: Hero

    private var heroIcon: some View {
        ZStack {
            Circle()
                .fill(Color.primaryText.opacity(0.07))
                .frame(width: 100, height: 100)
            Image(systemName: "wand.and.stars")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(.primaryText)
        }
        .scaleEffect(appeared ? 1 : 0.65)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.06), value: appeared)
    }

    // MARK: Title

    private var titleBlock: some View {
        VStack(spacing: 8) {
            Text(String(localized: "onboarding.paywall.title"))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primaryText)
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 14)
                .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.2), value: appeared)

            Text(String(localized: "onboarding.paywall.subtitle"))
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.27), value: appeared)
        }
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
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(
                    .spring(response: 0.55, dampingFraction: 0.82).delay(0.34 + Double(i) * 0.07),
                    value: appeared
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Bottom

    private var bottomBlock: some View {
        VStack(spacing: 12) {
            priceLabel

            OnboardingCTAButton(
                title: String(localized: "onboarding.paywall.cta"),
                isEnabled: !store.products.isEmpty,
                action: { Task { await store.purchase() } }
            )
            .padding(.horizontal, 24)

            Button(action: { Task { await store.restore() } }) {
                Text(String(localized: "onboarding.paywall.restore"))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            }

            HStack(spacing: 16) {
                Link(String(localized: "onboarding.paywall.terms"), destination: AppConfig.termsOfUseURL)
                Text("·")
                Link(String(localized: "onboarding.paywall.privacy"), destination: AppConfig.privacyPolicyURL)
            }
            .font(.system(size: 11, weight: .regular, design: .rounded))
            .foregroundStyle(.tertiary)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
        .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.58 + Double(benefits.count - 1) * 0.08), value: appeared)
    }

    // MARK: Price

    @ViewBuilder
    private var priceLabel: some View {
        if let price = store.products.first?.displayPrice {
            VStack(spacing: 6) {
                purchaseBadge

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(price)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.primaryText)

                    Text(String(localized: "onboarding.paywall.period"))
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
            Text(String(localized: "onboarding.paywall.onetime"))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(Color("collectionMindPattern"))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color("collectionMindPattern").opacity(0.12)))
    }
}

#Preview {
    OBPaywallScreen(onDismiss: {})
        .background(Color.background)
        .environmentObject(StoreManager())
}
