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

    func test_hasProAccess_isTrueWhenDevOverrideIsSetEvenWithoutStoreAccess() async {
        let service = MockStoreService()
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: service, defaults: MockPreferenceStore())

        XCTAssertFalse(manager.hasProAccess)
        manager.isProOverride = true

        XCTAssertTrue(manager.hasProAccess)
    }

    func test_isProOverride_writesThroughInjectedDefaultsNotUserDefaultsStandard() {
        let store = MockPreferenceStore()
        let manager = StoreManager(productIDs: ["magic_lifetime"], service: MockStoreService(), defaults: store)

        manager.isProOverride = true

        XCTAssertEqual(store.storage["dev.proOverride"] as? Bool, true)
    }
}

private final class MockStoreService: StoreServicing {
    var products: [StoreProduct] = []
    var purchaseResult: Result<StorePurchaseResult, Error> = .success(.success)
    var entitlementProductIDs: [String]
    var syncCallCount = 0
    var syncError: Error?

    init(entitlementProductIDs: [String] = []) {
        self.entitlementProductIDs = entitlementProductIDs
    }

    func loadProducts(for productIDs: [String]) async throws -> [StoreProduct] {
        products
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
        AsyncStream { $0.finish() }
    }

    func sync() async throws {
        syncCallCount += 1
        if let syncError { throw syncError }
    }
}

private final class MockPreferenceStore: PreferenceStoring {
    var storage: [String: Any] = [:]

    func object(forKey defaultName: String) -> Any? { storage[defaultName] }
    func bool(forKey defaultName: String) -> Bool { (storage[defaultName] as? Bool) ?? false }
    func double(forKey defaultName: String) -> Double { (storage[defaultName] as? Double) ?? 0 }
    func stringArray(forKey defaultName: String) -> [String]? { storage[defaultName] as? [String] }
    func set(_ value: Any?, forKey defaultName: String) { storage[defaultName] = value }
}
