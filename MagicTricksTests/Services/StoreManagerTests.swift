//
//  StoreManagerTests.swift
//  MagicTricksTests
//

import XCTest
@testable import MagicTricks

@MainActor
final class StoreManagerTests: XCTestCase {

    func test_restore_withMatchingEntitlement_grantsAccess() async {
        let service = MockStoreService(entitlementProductIDs: ["magic_lifetime"])
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore())

        await manager.restore()

        XCTAssertTrue(manager.hasProAccess)
    }

    func test_restore_withUnrelatedEntitlement_doesNotGrantAccess() async {
        let service = MockStoreService(entitlementProductIDs: ["some_other_product"])
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore())

        await manager.restore()

        XCTAssertFalse(manager.hasProAccess)
    }

    func test_restore_whenAlreadyHasStoreAccess_showsAlreadyProAndSkipsSync() async {
        let service = MockStoreService(entitlementProductIDs: ["magic_lifetime"])
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore())
        await manager.restore()
        XCTAssertNil(manager.alertMessage)

        await manager.restore()

        XCTAssertNotNil(manager.alertMessage)
        XCTAssertNotEqual(manager.alertTitle, String(localized: "common.error"))
        XCTAssertEqual(service.syncCallCount, 0)
    }

    func test_restore_withProOverrideOnAndNoStoreAccess_stillCallsSync() async {
        let service = MockStoreService()
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore())
        manager.isProOverride = true

        await manager.restore()

        XCTAssertEqual(service.syncCallCount, 1)
    }

    func test_purchase_whenUserCancelled_doesNotGrantAccess() async {
        let service = MockStoreService()
        service.purchaseResult = .success(.userCancelled)
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore())

        await manager.purchase(productID: "magic_lifetime")

        XCTAssertFalse(manager.hasProAccess)
    }

    func test_restore_callsSyncExactlyOnce() async {
        let service = MockStoreService()
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore())

        await manager.restore()

        XCTAssertEqual(service.syncCallCount, 1)
    }

    func test_restore_withProOverrideOnAndNothingToRestore_showsNoPurchasesAlert() async {
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: MockStoreService(), defaults: MockPreferenceStore())
        manager.isProOverride = true

        await manager.restore()

        XCTAssertNotNil(manager.alertMessage)
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

        await manager.restore()

        XCTAssertFalse(manager.hasProAccess)
        XCTAssertNotNil(manager.alertMessage)
        XCTAssertEqual(manager.alertTitle, String(localized: "common.error"))
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

        await manager.purchase(productID: "magic_lifetime")

        XCTAssertTrue(manager.hasProAccess)
    }

    func test_purchase_whenThrows_doesNotGrantAccessAndSetsAlert() async {
        let service = MockStoreService()
        service.purchaseResult = .failure(MockStoreServiceError.requestedFailure)
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore())

        await manager.purchase(productID: "magic_lifetime")

        XCTAssertFalse(manager.hasProAccess)
        XCTAssertNotNil(manager.alertMessage)
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

        await manager.purchase(productID: "magic_lifetime")

        XCTAssertFalse(manager.hasProAccess)
        XCTAssertNotNil(manager.alertMessage)
    }

    func test_transactionUpdate_grantsAccess() async {
        let service = MockStoreService()
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore())

        manager.start()
        await flushPendingTasks()
        XCTAssertFalse(manager.hasProAccess)

        service.entitlementProductIDs = ["magic_lifetime"]
        service.emitTransactionUpdate(productID: "magic_lifetime")
        await flushPendingTasks()

        XCTAssertTrue(manager.hasProAccess)
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

    // Lets fire-and-forget Task {} blocks under test finish before we assert on them.
    private func flushPendingTasks() async {
        for _ in 0..<10 { await Task.yield() }
    }
}

private final class MockStoreService: StoreServicing {
    var products: [StoreProduct] = []
    var loadProductsError: Error?
    var loadProductsCallCount = 0
    var purchaseResult: Result<StorePurchaseResult, Error> = .success(.success)
    var entitlementProductIDs: [String]
    var syncCallCount = 0
    var syncError: Error?
    private var transactionContinuation: AsyncStream<String>.Continuation?

    init(entitlementProductIDs: [String] = []) {
        self.entitlementProductIDs = entitlementProductIDs
    }

    func loadProducts(for productIDs: [String]) async throws -> [StoreProduct] {
        loadProductsCallCount += 1
        if let loadProductsError { throw loadProductsError }
        return products
    }

    func purchase(productID: String) async throws -> StorePurchaseResult {
        try purchaseResult.get()
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

    func emitTransactionUpdate(productID: String) {
        transactionContinuation?.yield(productID)
    }

    func sync() async throws {
        syncCallCount += 1
        if let syncError { throw syncError }
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
