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

enum StoreError: Error, Equatable {
    case verificationFailed
    case productNotFound
    case cancelled
    case network

    // Known StoreKit and URL failures become a StoreError; anything else passes through unchanged.
    static func classify(_ error: Error) -> Error {
        switch error {
        case let known as StoreError:
            return known
        case is CancellationError:
            return StoreError.cancelled
        case let kit as StoreKitError:
            switch kit {
            case .userCancelled: return StoreError.cancelled
            case .networkError: return StoreError.network
            default: return error
            }
        case is URLError:
            return StoreError.network
        default:
            return error
        }
    }
}

// MARK: - Protocol

@MainActor
protocol StoreServicing {
    func loadProducts(for productIDs: [String]) async throws -> [StoreProduct]
    func purchase(productID: String) async throws -> StorePurchaseResult
    func currentEntitlementProductIDs() -> AsyncStream<String>
    func transactionUpdateProductIDs() -> AsyncStream<String>
    func sync() async throws
}

// MARK: - StoreKit 2 implementation

@MainActor
final class StoreKitStoreService: StoreServicing {
    private var productsByID: [String: Product] = [:]

    func loadProducts(for productIDs: [String]) async throws -> [StoreProduct] {
        let products = try await Product.products(for: productIDs)
        productsByID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        return products.map(StoreProduct.init)
    }

    func purchase(productID: String) async throws -> StorePurchaseResult {
        guard let product = productsByID[productID] else { throw StoreError.productNotFound }

        let result: Product.PurchaseResult
        do {
            result = try await product.purchase()
        } catch {
            throw StoreError.classify(error)
        }

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
        do {
            try await AppStore.sync()
        } catch {
            throw StoreError.classify(error)
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw StoreError.verificationFailed
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
