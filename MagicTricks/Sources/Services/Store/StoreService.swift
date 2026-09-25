//
//  StoreService.swift
//  Magic Tricks
//
//  Created by Ross on 11/06/2026.
//

import Foundation
import StoreKit

// MARK: - Result

enum StorePurchaseResult: Equatable {
    case success
    case userCancelled
    case pending
}

// MARK: - Protocol

protocol StoreServicing {
    func loadProducts(for productIDs: [String]) async throws -> [StoreProduct]
    func purchase(productID: String) async throws -> StorePurchaseResult
    func currentEntitlementProductIDs() -> AsyncStream<String>
    func transactionUpdateProductIDs() -> AsyncStream<String>
    func sync() async throws
}

// MARK: - StoreKit 2 implementation

final class StoreKitStoreService: StoreServicing {
    private var productsByID: [String: Product] = [:]

    func loadProducts(for productIDs: [String]) async throws -> [StoreProduct] {
        let products = try await Product.products(for: productIDs)
        productsByID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        return products.map(StoreProduct.init)
    }

    func purchase(productID: String) async throws -> StorePurchaseResult {
        guard let product = productsByID[productID] else { return .userCancelled }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            return .success
        case .userCancelled:
            return .userCancelled
        case .pending:
            return .pending
        @unknown default:
            return .pending
        }
    }

    func currentEntitlementProductIDs() -> AsyncStream<String> {
        AsyncStream { continuation in
            let task = Task {
                for await result in Transaction.currentEntitlements {
                    if let productID = try? checkVerified(result).productID {
                        continuation.yield(productID)
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func transactionUpdateProductIDs() -> AsyncStream<String> {
        AsyncStream { continuation in
            let task = Task {
                for await result in Transaction.updates {
                    if let transaction = try? checkVerified(result) {
                        await transaction.finish()
                        continuation.yield(transaction.productID)
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func sync() async throws {
        try await AppStore.sync()
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw StoreKitError.userCancelled
        case .verified(let value): return value
        }
    }
}

// MARK: - StoreProduct init from StoreKit Product

private extension StoreProduct {
    init(_ product: Product) {
        self.init(
            id: product.id,
            displayName: product.displayName,
            displayPrice: product.displayPrice
        )
    }
}
