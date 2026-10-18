//
//  StoreManager.swift
//  Magic Tricks
//
//  Created by Ross on 11/06/2026.
//

import Foundation

// MARK: - Alert

// Returned to the screen that started the action, so it shows the alert itself and it can't surface somewhere else.
struct StoreAlert: Equatable {
    let title: String
    let message: String

    fileprivate static func error(_ key: String) -> StoreAlert {
        StoreAlert(title: .commonError, message: .paywallError(key))
    }

    fileprivate static let alreadyPro = StoreAlert(title: .paywallInfo("alreadyPro.title"), message: .paywallInfo("alreadyPro"))
    fileprivate static let restored = StoreAlert(title: .paywallInfo("restored.title"), message: .paywallInfo("restored"))

    // A cancelled sign-in or purchase sheet is the user's own choice, not an error, so it gets no alert.
    fileprivate static func failure(_ error: Error, fallback: String) -> StoreAlert? {
        switch StoreError.classify(error) as? StoreError {
        case .cancelled: nil
        case .verificationFailed: .error("verificationFailed")
        case .network: .error("network")
        default: .error(fallback)
        }
    }
}

// MARK: - Manager

@MainActor
final class StoreManager: ObservableObject {

    private enum StoreProducts {
        static let lifetime = "magic_lifetime"
        static let all = [lifetime]
    }

    private enum Key {
        static let proOverride = "dev.proOverride"
        static let watermarkHidden = "dev.watermarkHidden"
    }

    @Published private(set) var products: [StoreProduct] = []
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isPurchasing = false
    @Published private(set) var isRestoring = false
    @Published private(set) var hasResolvedAccess = false
    @Published private(set) var productsLoadError: String?
    @Published private var _hasStoreAccess: Bool = false
    @Published var isProOverride: Bool {
        didSet { defaults.set(isProOverride, forKey: Key.proOverride) }
    }
    @Published var isWatermarkHidden: Bool {
        didSet { defaults.set(isWatermarkHidden, forKey: Key.watermarkHidden) }
    }

    // Loading prices doesn't count: Restore needs no prices.
    var isTransacting: Bool { isPurchasing || isRestoring }

    // False only until the first purchase check finishes, when an owner would otherwise see locks flash.
    var isAccessKnown: Bool { hasResolvedAccess || (isInternalBuild && isProOverride) }

    // What the UI shows as the free tier: locks, the Unlock button and the watermark.
    var showsFreeTier: Bool { isAccessKnown && !hasProAccess }

    // The tester toggles do nothing in a release build, whatever the stored flags say.
    var hasProAccess: Bool { _hasStoreAccess || (isInternalBuild && isProOverride) }
    var isWatermarkSuppressed: Bool { isInternalBuild && isWatermarkHidden }

    private let productIDs: [String]
    private let service: StoreServicing
    private let defaults: PreferenceStoring
    private let isInternalBuild: Bool

    private var startupTask: Task<Void, Never>?
    private var listenerTask: Task<Void, Never>?
    private var loadProductsTask: Task<Void, Never>?
    private var hasStarted = false

    init(
        productIDs: [String] = StoreProducts.all,
        service: StoreServicing? = nil,
        defaults: PreferenceStoring = UserDefaults.standard,
        isInternalBuild: Bool = AppBuildEnvironment.isInternalBuild
    ) {
        self.productIDs = productIDs
        self.service = service ?? StoreKitStoreService()
        self.defaults = defaults
        self.isInternalBuild = isInternalBuild
        self.isProOverride = Self.internalBuildGatedFlag(forKey: Key.proOverride, defaults: defaults, isInternalBuild: isInternalBuild)
        self.isWatermarkHidden = Self.internalBuildGatedFlag(forKey: Key.watermarkHidden, defaults: defaults, isInternalBuild: isInternalBuild)
    }

    private static func internalBuildGatedFlag(forKey key: String, defaults: PreferenceStoring, isInternalBuild: Bool) -> Bool {
        guard isInternalBuild else {
            if defaults.bool(forKey: key) {
                // Property observers don't fire during init, so this write is explicit.
                defaults.set(false, forKey: key)
            }
            return false
        }
        return defaults.bool(forKey: key)
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
            // Purchases first: that is local and quick, while loading prices needs the network and can be slow.
            await self?.refreshAccess()
            await self?.loadProducts()
        }

        listenerTask = Task { [weak self] in
            guard let updates = self?.service.transactionUpdateProductIDs() else { return }
            for await productID in updates {
                // Strong only for one update, so an idle listener doesn't keep the manager alive.
                guard let self else { return }
                if productIDs.contains(productID) {
                    await refreshAccess()
                }
            }
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

    func purchase(productID: String) async -> StoreAlert? {
        guard !isTransacting else { return nil }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            switch try await service.purchase(productID: productID) {
            case .success:
                await refreshAccess()
                return nil
            case .userCancelled:
                return nil
            case .pending:
                return .error("pending")
            }
        } catch {
            return .failure(error, fallback: "purchaseFailed")
        }
    }

    func restore() async -> StoreAlert? {
        guard !isTransacting else { return nil }
        isRestoring = true
        defer { isRestoring = false }

        let hadStoreAccess = _hasStoreAccess
        await refreshAccess()
        guard !_hasStoreAccess else {
            return hadStoreAccess ? .alreadyPro : .restored
        }

        do {
            try await service.sync()
            await refreshAccess()
            return _hasStoreAccess ? .restored : .error("noPurchasesFound")
        } catch {
            return .failure(error, fallback: "restoreFailed")
        }
    }

    func waitForResolvedAccess() async {
        guard !isAccessKnown else { return }
        for await resolved in $hasResolvedAccess.values where resolved { return }
    }

    func retryLoadProducts() async {
        await loadProducts()
    }

    func reloadProductsIfNeeded() async {
        guard products.isEmpty else { return }
        await loadProducts()
    }

    // MARK: Private

    // Joins an in-flight load instead of starting a duplicate - start(), reloadProductsIfNeeded(),
    // and retryLoadProducts() can all reach here around the same time.
    private func loadProducts() async {
        if let loadProductsTask {
            await loadProductsTask.value
            return
        }
        let task = Task { [weak self] in
            guard let self else { return }
            await self.performLoadProducts()
        }
        loadProductsTask = task
        await task.value
        loadProductsTask = nil
    }

    private func performLoadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            products = try await service.loadProducts(for: productIDs)
            #if DEBUG
            if products.isEmpty { print("[Store] no products returned for \(productIDs); is a StoreKit configuration attached to the scheme?") }
            #endif
            productsLoadError = products.isEmpty ? .paywallError("productsLoadFailed") : nil
        } catch {
            #if DEBUG
            print("[Store] loadProducts failed: \(error)")
            #endif
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
        hasResolvedAccess = true
    }
}

private extension String {
    static func paywallError(_ key: String) -> String {
        NSLocalizedString("onboarding.paywall.error.\(key)", comment: "")
    }

    static var commonError: String { String(localized: "common.error") }

    static func paywallInfo(_ key: String) -> String {
        NSLocalizedString("onboarding.paywall.info.\(key)", comment: "")
    }
}
