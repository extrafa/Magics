//
//  StoreManager.swift
//  Magic Tricks
//
//  Created by Ross on 11/06/2026.
//

import Foundation

// MARK: - Phase

enum PurchasePhase: Equatable {
    case idle
    case purchasing
    case restoring
    case loadingProducts
}

// MARK: - Manager

@MainActor
final class StoreManager: ObservableObject {

    private enum StoreProducts {
        static let lifetime = "magic_lifetime"
        static let all = [lifetime]
    }

    @Published private(set) var products: [StoreProduct] = []
    @Published private(set) var phase: PurchasePhase = .idle
    @Published var alertMessage: String?
    @Published private(set) var productsLoadError: String?
    @Published private var _hasStoreAccess: Bool = false
    @Published var isProOverride: Bool {
        didSet { UserDefaults.standard.set(isProOverride, forKey: "dev.proOverride") }
    }
    @Published var isWatermarkHidden: Bool {
        didSet { UserDefaults.standard.set(isWatermarkHidden, forKey: "dev.watermarkHidden") }
    }

    var hasProAccess: Bool { _hasStoreAccess || isProOverride }

    private let productIDs: [String]
    private let service: StoreServicing

    private var startupTask: Task<Void, Never>?
    private var listenerTask: Task<Void, Never>?
    private var hasStarted = false

    init(
        productIDs: [String] = StoreProducts.all,
        service: StoreServicing = StoreKitStoreService()
    ) {
        self.productIDs = productIDs
        self.service = service
        self.isProOverride = UserDefaults.standard.bool(forKey: "dev.proOverride")
        self.isWatermarkHidden = UserDefaults.standard.bool(forKey: "dev.watermarkHidden")
    }

    deinit {
        startupTask?.cancel()
        listenerTask?.cancel()
    }

    // MARK: Lifecycle

    func start() {
        guard !hasStarted else { return }
        hasStarted = true

        startupTask = Task { [weak self] in
            await self?.loadProducts()
            await self?.refreshAccess()
        }

        listenerTask = Task { [weak self] in
            await self?.listenForTransactions()
        }
    }

    func stop() {
        startupTask?.cancel()
        listenerTask?.cancel()
        startupTask = nil
        listenerTask = nil
        hasStarted = false
    }

    // MARK: Actions

    func purchase() async {
        guard let id = products.first?.id else {
            alertMessage = .paywallError("productsLoadFailed")
            return
        }
        phase = .purchasing
        defer { phase = .idle }
        do {
            switch try await service.purchase(productID: id) {
            case .success:
                await refreshAccess()
            case .userCancelled:
                break
            case .pending:
                alertMessage = .paywallError("pending")
            }
        } catch {
            alertMessage = .paywallError("purchaseFailed")
        }
    }

    func restore() async {
        phase = .restoring
        defer { phase = .idle }
        do {
            try await service.sync()
            await refreshAccess()
            if !hasProAccess {
                alertMessage = .paywallError("noPurchasesFound")
            }
        } catch {
            alertMessage = .paywallError("restoreFailed")
        }
    }

    func retryLoadProducts() async {
        await loadProducts()
    }

    // MARK: Private

    private func loadProducts() async {
        phase = .loadingProducts
        defer { phase = .idle }
        do {
            products = try await service.loadProducts(for: productIDs)
            productsLoadError = products.isEmpty ? .paywallError("productsLoadFailed") : nil
        } catch {
            productsLoadError = .paywallError("productsLoadFailed")
        }
    }

    private func refreshAccess() async {
        var found = false
        for await productID in service.currentEntitlementProductIDs() {
            if productIDs.contains(productID) {
                found = true
            }
        }
        _hasStoreAccess = found
    }

    private func listenForTransactions() async {
        for await productID in service.transactionUpdateProductIDs() {
            if productIDs.contains(productID) {
                await refreshAccess()
            }
        }
    }
}

private extension String {
    static func paywallError(_ key: String) -> String {
        NSLocalizedString("onboarding.paywall.error.\(key)", comment: "")
    }
}
