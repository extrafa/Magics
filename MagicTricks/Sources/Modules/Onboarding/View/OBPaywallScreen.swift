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

    private let benefits: [LocalizedStringKey] = [
        "onboarding.paywall.benefit1",
        "onboarding.paywall.benefit2",
        "onboarding.paywall.benefit3",
        "onboarding.paywall.benefit4",
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            heroIcon
                .padding(.bottom, 20)

            titleBlock
                .padding(.horizontal, 32)
                .padding(.bottom, 28)
                .padding(.top, 4)

            benefitsList
                .padding(.horizontal, 36)

            Spacer()

            bottomBlock
                .padding(.bottom, 48)
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
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.primaryText)

                    Text(benefits[i])
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.primaryText)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(
                    .spring(response: 0.55, dampingFraction: 0.82).delay(0.34 + Double(i) * 0.08),
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

            HStack(spacing: 20) {
                Button(action: onDismiss) {
                    Text(String(localized: "onboarding.paywall.skip"))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }

                Button(action: { Task { await store.restore() } }) {
                    Text(String(localized: "onboarding.paywall.restore"))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
        .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.58 + Double(benefits.count - 1) * 0.08), value: appeared)
    }

    @ViewBuilder
    private var priceLabel: some View {
        if let price = store.products.first?.displayPrice {
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

#Preview {
    OBPaywallScreen(onDismiss: {})
        .background(Color.background)
        .environmentObject(StoreManager())
}
