//
//  StoreManagerTests.swift
//  MagicTricksTests
//

import StoreKit
import XCTest
@testable import MagicTricks

@MainActor
final class StoreManagerTests: XCTestCase {

    func test_restore_withMatchingEntitlement_grantsAccess() async {
        let service = MockStoreService(entitlementProductIDs: ["magic_lifetime"])
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore())

        _ = await manager.restore()

        XCTAssertTrue(manager.hasProAccess)
    }

    func test_restore_withUnrelatedEntitlement_doesNotGrantAccess() async {
        let service = MockStoreService(entitlementProductIDs: ["some_other_product"])
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore())

        _ = await manager.restore()

        XCTAssertFalse(manager.hasProAccess)
    }

    func test_restore_whenAlreadyHasStoreAccess_showsAlreadyProAndSkipsSync() async {
        let service = MockStoreService(entitlementProductIDs: ["magic_lifetime"])
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore())
        let first = await manager.restore()
        XCTAssertEqual(first?.message, NSLocalizedString("onboarding.paywall.info.restored", comment: ""))

        let alert = await manager.restore()

        XCTAssertNotNil(alert)
        XCTAssertNotEqual(alert?.title, String(localized: "common.error"))
        XCTAssertEqual(service.syncCallCount, 0)
    }

    func test_restore_withProOverrideOnAndNoStoreAccess_stillCallsSync() async {
        let service = MockStoreService()
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore())
        manager.isProOverride = true

        _ = await manager.restore()

        XCTAssertEqual(service.syncCallCount, 1)
    }

    func test_purchase_whenUserCancelled_doesNotGrantAccess() async {
        let service = MockStoreService()
        service.purchaseResult = .success(.userCancelled)
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore())

        _ = await manager.purchase(productID: "magic_lifetime")

        XCTAssertFalse(manager.hasProAccess)
    }

    func test_restore_callsSyncExactlyOnce() async {
        let service = MockStoreService()
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore())

        _ = await manager.restore()

        XCTAssertEqual(service.syncCallCount, 1)
    }

    func test_restore_withProOverrideOnAndNothingToRestore_showsNoPurchasesAlert() async {
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: MockStoreService(), defaults: MockPreferenceStore())
        manager.isProOverride = true

        let alert = await manager.restore()

        XCTAssertNotNil(alert)
    }

    func test_hasProAccess_isTrueWhenDevOverrideIsSetEvenWithoutStoreAccess() async {
        let service = MockStoreService()
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore())

        XCTAssertFalse(manager.hasProAccess)
        manager.isProOverride = true

        XCTAssertTrue(manager.hasProAccess)
    }

    func test_restore_whenSyncFails_showsAlertAndDoesNotGrantAccess() async {
        let service = MockStoreService()
        service.syncError = MockStoreServiceError.requestedFailure
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore())

        let alert = await manager.restore()

        XCTAssertFalse(manager.hasProAccess)
        XCTAssertNotNil(alert)
        XCTAssertEqual(alert?.title, String(localized: "common.error"))
    }

    func test_isProOverride_writesThroughInjectedDefaultsNotUserDefaultsStandard() {
        let store = MockPreferenceStore()
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: MockStoreService(), defaults: store)

        manager.isProOverride = true

        XCTAssertEqual(store.storage["dev.proOverride"] as? Bool, true)
    }

    func test_purchase_whenSuccessful_grantsAccess() async {
        let service = MockStoreService(entitlementProductIDs: ["magic_lifetime"])
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore())

        _ = await manager.purchase(productID: "magic_lifetime")

        XCTAssertTrue(manager.hasProAccess)
    }

    func test_purchase_whenThrows_doesNotGrantAccessAndSetsAlert() async {
        let service = MockStoreService()
        service.purchaseResult = .failure(MockStoreServiceError.requestedFailure)
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore())

        let alert = await manager.purchase(productID: "magic_lifetime")

        XCTAssertFalse(manager.hasProAccess)
        XCTAssertNotNil(alert)
    }

    func test_storeKitService_purchaseOfUnloadedProduct_throwsProductNotFound() async {
        do {
            _ = try await StoreKitStoreService().purchase(productID: "magic_lifetime")
            XCTFail("Expected purchase to throw")
        } catch {
            XCTAssertEqual(error as? StoreError, .productNotFound)
        }
    }

    func test_purchase_whenPending_doesNotGrantAccessAndSetsAlert() async {
        let service = MockStoreService()
        service.purchaseResult = .success(.pending)
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore())

        let alert = await manager.purchase(productID: "magic_lifetime")

        XCTAssertFalse(manager.hasProAccess)
        XCTAssertNotNil(alert)
    }

    func test_transactionUpdate_grantsAccess() async {
        let service = MockStoreService()
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore())

        manager.start()
        await waitUntil { service.isListeningForTransactions }
        XCTAssertFalse(manager.hasProAccess)

        service.entitlementProductIDs = ["magic_lifetime"]
        service.emitTransactionUpdate(productID: "magic_lifetime")
        await waitUntil { manager.hasProAccess }

        XCTAssertTrue(manager.hasProAccess)
    }

    func test_start_grantsAccessWithoutWaitingForProductsToLoad() async {
        let service = MockStoreService(entitlementProductIDs: ["magic_lifetime"])
        service.loadProductsNeverReturns = true
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore())

        manager.start()
        await waitUntil { manager.hasProAccess }

        XCTAssertTrue(manager.hasProAccess)
        manager.stop()
    }

    func test_retryLoadProducts_whenSuccessful_populatesProductsAndClearsError() async {
        let service = MockStoreService()
        service.products = [StoreProduct(id: "magic_lifetime", displayName: "Lifetime", displayPrice: "$9.99")]
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore())

        await manager.retryLoadProducts()

        XCTAssertEqual(manager.products.map(\.id), ["magic_lifetime"])
        XCTAssertNil(manager.productsLoadError)
    }

    func test_retryLoadProducts_whenThrows_setsProductsLoadError() async {
        let service = MockStoreService()
        service.loadProductsError = MockStoreServiceError.requestedFailure
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore())

        await manager.retryLoadProducts()

        XCTAssertTrue(manager.products.isEmpty)
        XCTAssertNotNil(manager.productsLoadError)
    }

    func test_reloadProductsIfNeeded_whenProductsAlreadyLoaded_doesNotReload() async {
        let service = MockStoreService()
        service.products = [StoreProduct(id: "magic_lifetime", displayName: "Lifetime", displayPrice: "$9.99")]
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore())
        await manager.retryLoadProducts()
        XCTAssertEqual(service.loadProductsCallCount, 1)

        await manager.reloadProductsIfNeeded()

        XCTAssertEqual(service.loadProductsCallCount, 1)
    }

    func test_manager_isReleasedWhileListeningForTransactions() async {
        let service = MockStoreService()
        weak var weakManager: StoreManager?

        do {
            let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore())
            weakManager = manager
            manager.start()
            await waitUntil { service.isListeningForTransactions }
        }

        await waitUntil { weakManager == nil }
    }

    func test_releaseBuild_ignoresStoredAndSetTesterFlags() {
        let store = MockPreferenceStore()
        store.storage["dev.proOverride"] = true
        store.storage["dev.watermarkHidden"] = true
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: MockStoreService(), defaults: store, isInternalBuild: false)

        XCTAssertFalse(manager.isProOverride)
        XCTAssertFalse(manager.isWatermarkHidden)
        XCTAssertEqual(store.storage["dev.proOverride"] as? Bool, false)

        manager.isProOverride = true
        manager.isWatermarkHidden = true

        XCTAssertFalse(manager.hasProAccess)
        XCTAssertFalse(manager.isWatermarkSuppressed)
    }

    func test_internalBuild_honoursTesterFlags() {
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: MockStoreService(), defaults: MockPreferenceStore(), isInternalBuild: true)

        manager.isProOverride = true
        manager.isWatermarkHidden = true

        XCTAssertTrue(manager.hasProAccess)
        XCTAssertTrue(manager.isWatermarkSuppressed)
    }

    func test_restore_runsWhileProductsAreStillLoading() async {
        let service = MockStoreService(entitlementProductIDs: ["magic_lifetime"])
        service.loadProductsNeverReturns = true
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore())
        let loading = Task { await manager.retryLoadProducts() }
        await waitUntil { manager.isLoadingProducts }

        _ = await manager.restore()

        XCTAssertTrue(manager.hasProAccess)
        XCTAssertFalse(manager.isRestoring)
        XCTAssertTrue(manager.isLoadingProducts)
        loading.cancel()
    }

    func test_finishingProductsLoad_doesNotClearAnInFlightPurchase() async {
        let service = MockStoreService()
        service.purchaseNeverReturns = true
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore())
        let purchasing = Task { await manager.purchase(productID: "magic_lifetime") }
        await waitUntil { manager.isPurchasing }

        await manager.retryLoadProducts()

        XCTAssertTrue(manager.isPurchasing)
        XCTAssertFalse(manager.isLoadingProducts)
        purchasing.cancel()
    }

    func test_restore_isIgnoredWhileAPurchaseIsInFlight() async {
        let service = MockStoreService()
        service.purchaseNeverReturns = true
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore())
        let purchasing = Task { await manager.purchase(productID: "magic_lifetime") }
        await waitUntil { manager.isPurchasing }

        _ = await manager.restore()

        XCTAssertEqual(service.syncCallCount, 0)
        XCTAssertFalse(manager.isRestoring)
        XCTAssertTrue(manager.isTransacting)
        purchasing.cancel()
    }

    func test_flags_areClearedAfterPurchaseRestoreAndLoad() async {
        let service = MockStoreService(entitlementProductIDs: ["magic_lifetime"])
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore())

        _ = await manager.purchase(productID: "magic_lifetime")
        _ = await manager.restore()
        await manager.retryLoadProducts()

        XCTAssertFalse(manager.isPurchasing)
        XCTAssertFalse(manager.isRestoring)
        XCTAssertFalse(manager.isLoadingProducts)
    }

    func test_restore_afterSyncFindsAPurchase_reportsRestored() async {
        let service = MockStoreService()
        service.entitlementProductIDsAfterSync = ["magic_lifetime"]
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore())

        let alert = await manager.restore()

        XCTAssertTrue(manager.hasProAccess)
        XCTAssertEqual(alert?.title, NSLocalizedString("onboarding.paywall.info.restored.title", comment: ""))
    }

    func test_restore_whenTheUserCancelsTheSignIn_showsNoAlert() async {
        let service = MockStoreService()
        service.syncError = StoreError.cancelled
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore())

        let alert = await manager.restore()

        XCTAssertNil(alert)
    }

    func test_restore_onANetworkError_asksToCheckTheConnection() async {
        let service = MockStoreService()
        service.syncError = StoreError.network
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore())

        let alert = await manager.restore()

        XCTAssertEqual(alert?.message, NSLocalizedString("onboarding.paywall.error.network", comment: ""))
    }

    func test_purchase_whenVerificationFails_doesNotSuggestTryingAgain() async {
        let service = MockStoreService()
        service.purchaseResult = .failure(StoreError.verificationFailed)
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore())

        let alert = await manager.purchase(productID: "magic_lifetime")

        XCTAssertEqual(alert?.message, NSLocalizedString("onboarding.paywall.error.verificationFailed", comment: ""))
    }

    func test_purchase_whenTheUserCancelsTheSheetWithAnError_showsNoAlert() async {
        let service = MockStoreService()
        service.purchaseResult = .failure(StoreError.cancelled)
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore())

        let alert = await manager.purchase(productID: "magic_lifetime")

        XCTAssertNil(alert)
    }

    func test_classify_mapsStoreKitAndURLFailures() {
        XCTAssertEqual(StoreError.classify(StoreKitError.userCancelled) as? StoreError, .cancelled)
        XCTAssertEqual(StoreError.classify(StoreKitError.networkError(URLError(.notConnectedToInternet))) as? StoreError, .network)
        XCTAssertEqual(StoreError.classify(URLError(.timedOut)) as? StoreError, .network)
        XCTAssertEqual(StoreError.classify(CancellationError()) as? StoreError, .cancelled)
        XCTAssertEqual(StoreError.classify(StoreError.verificationFailed) as? StoreError, .verificationFailed)
        XCTAssertNil(StoreError.classify(MockStoreServiceError.requestedFailure) as? StoreError)
    }

    func test_access_isUnknownUntilTheFirstCheckFinishes() async {
        let service = MockStoreService()
        service.loadProductsNeverReturns = true
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore(), isInternalBuild: false)

        XCTAssertFalse(manager.isAccessKnown)
        XCTAssertFalse(manager.showsFreeTier)

        manager.start()
        await waitUntil { manager.isAccessKnown }

        XCTAssertTrue(manager.showsFreeTier)
        manager.stop()
    }

    func test_owner_neverShowsTheFreeTier() async {
        let service = MockStoreService(entitlementProductIDs: ["magic_lifetime"])
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore(), isInternalBuild: false)

        XCTAssertFalse(manager.showsFreeTier)
        manager.start()
        await waitUntil { manager.isAccessKnown }

        XCTAssertTrue(manager.hasProAccess)
        XCTAssertFalse(manager.showsFreeTier)
        manager.stop()
    }

    func test_waitForResolvedAccess_returnsOnceTheFirstCheckFinishes() async {
        let service = MockStoreService(entitlementProductIDs: ["magic_lifetime"])
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore(), isInternalBuild: false)

        let waiting = Task { await manager.waitForResolvedAccess() }
        manager.start()
        await waiting.value

        XCTAssertTrue(manager.isAccessKnown)
        XCTAssertTrue(manager.hasProAccess)
        manager.stop()
    }

    func test_proOverride_makesAccessKnownImmediately_inAnInternalBuild() {
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: MockStoreService(), defaults: MockPreferenceStore(), isInternalBuild: true)

        manager.isProOverride = true

        XCTAssertTrue(manager.isAccessKnown)
        XCTAssertFalse(manager.showsFreeTier)
    }

    func test_isLocked_isStrictAndKeepsPhantomDrawAndGeoOpen() {
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: MockStoreService(), defaults: MockPreferenceStore(), isInternalBuild: false)

        XCTAssertTrue(manager.isLocked(.colorSense))
        XCTAssertTrue(manager.isLocked(.timeControl))
        XCTAssertTrue(manager.isLocked(.magicGallery))
        XCTAssertFalse(manager.isLocked(.phantomDraw))
        XCTAssertFalse(manager.isLocked(.geoMentalism))
    }

    func test_showsLock_appearsOnlyOnceTheFreeTierIsKnown() async {
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: MockStoreService(), defaults: MockPreferenceStore(), isInternalBuild: false)
        XCTAssertFalse(manager.showsLock(for: .colorSense))

        manager.start()
        await waitUntil { manager.isAccessKnown }

        XCTAssertTrue(manager.showsLock(for: .colorSense))
        XCTAssertFalse(manager.showsLock(for: .phantomDraw))
        XCTAssertFalse(manager.showsLock(for: .geoMentalism))
        manager.stop()
    }

    func test_owner_hasNoLocks() async {
        let service = MockStoreService(entitlementProductIDs: ["magic_lifetime"])
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore(), isInternalBuild: false)

        manager.start()
        await waitUntil { manager.isAccessKnown }

        XCTAssertFalse(manager.isLocked(.colorSense))
        XCTAssertFalse(manager.showsLock(for: .colorSense))
        manager.stop()
    }

    // Waits for a state change driven by a fire-and-forget Task inside StoreManager, failing on timeout.
    private func waitUntil(
        timeout: TimeInterval = 2,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ condition: () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            guard Date() < deadline else {
                XCTFail("Timed out waiting for condition", file: file, line: line)
                return
            }
            try? await Task.sleep(nanoseconds: 1_000_000)
        }
    }
}

private final class MockStoreService: StoreServicing {
    var products: [StoreProduct] = []
    var loadProductsError: Error?
    var loadProductsNeverReturns = false
    var purchaseNeverReturns = false
    var loadProductsCallCount = 0
    var purchaseResult: Result<StorePurchaseResult, Error> = .success(.success)
    var entitlementProductIDs: [String]
    var syncCallCount = 0
    var syncError: Error?
    var entitlementProductIDsAfterSync: [String]?
    private var transactionContinuation: AsyncStream<String>.Continuation?

    init(entitlementProductIDs: [String] = []) {
        self.entitlementProductIDs = entitlementProductIDs
    }

    func loadProducts(for productIDs: [String]) async throws -> [StoreProduct] {
        loadProductsCallCount += 1
        if loadProductsNeverReturns { try await Task.sleep(seconds: 3600) }
        if let loadProductsError { throw loadProductsError }
        return products
    }

    func purchase(productID: String) async throws -> StorePurchaseResult {
        if purchaseNeverReturns { try await Task.sleep(seconds: 3600) }
        return try purchaseResult.get()
    }

    func currentEntitlementProductIDs() -> AsyncStream<String> {
        AsyncStream { continuation in
            for id in entitlementProductIDs { continuation.yield(id) }
            continuation.finish()
        }
    }

    func transactionUpdateProductIDs() -> AsyncStream<String> {
        AsyncStream { continuation in
            transactionContinuation = continuation
        }
    }

    var isListeningForTransactions: Bool { transactionContinuation != nil }

    func emitTransactionUpdate(productID: String) {
        transactionContinuation?.yield(productID)
    }

    func sync() async throws {
        syncCallCount += 1
        if let syncError { throw syncError }
        if let entitlementProductIDsAfterSync { entitlementProductIDs = entitlementProductIDsAfterSync }
    }
}

private enum MockStoreServiceError: Error {
    case requestedFailure
}

private final class MockPreferenceStore: PreferenceStoring {
    var storage: [String: Any] = [:]

    func object(forKey defaultName: String) -> Any? { storage[defaultName] }
    func bool(forKey defaultName: String) -> Bool { (storage[defaultName] as? Bool) ?? false }
    func double(forKey defaultName: String) -> Double { (storage[defaultName] as? Double) ?? 0 }
    func integer(forKey defaultName: String) -> Int { (storage[defaultName] as? Int) ?? 0 }
    func stringArray(forKey defaultName: String) -> [String]? { storage[defaultName] as? [String] }
    func set(_ value: Any?, forKey defaultName: String) { storage[defaultName] = value }
}
