//
//  PaywallScreen+Previews.swift
//  Magic Tricks
//

import SwiftUI

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

#Preview("Magic Gallery") {
    PaywallScreen(context: .trick(.magicGallery), onDismiss: {})
        .background(Color.backgroundScreen)
        .environmentObject(StoreManager(service: PaywallPreviewStoreService()))
}
#endif
