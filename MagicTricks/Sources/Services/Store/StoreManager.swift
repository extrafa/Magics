//
//  StoreManager.swift
//  Magic Tricks
//
//  Created by Ross on 11/06/2026.
//

import Foundation

@MainActor
final class StoreManager: ObservableObject {

    private enum StoreProducts {
        static let lifetime = "magic_lifetime"
        static let all = [lifetime]
    }

    @Published private(set) var products: [StoreProduct] = []
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
        guard let id = products.first?.id else { return }
        do {
            let result = try await service.purchase(productID: id)
            if result == .success {
                await refreshAccess()
            }
        } catch { }
    }

    func restore() async {
        do {
            try await service.sync()
            await refreshAccess()
        } catch { }
    }

    // MARK: Private

    private func loadProducts() async {
        do {
            products = try await service.loadProducts(for: productIDs)
        } catch { }
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
