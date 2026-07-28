import Foundation

enum StoreProducts {
    static let lifetime = "magic_lifetime"
    static let all = [lifetime]
}

@MainActor
final class StoreManager: ObservableObject {

    @Published private(set) var products: [StoreProduct] = []
    @Published private(set) var hasProAccess: Bool = false

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
        } catch {
            // Purchase failed — user can retry
        }
    }

    func restore() async {
        do {
            try await service.sync()
            await refreshAccess()
        } catch {
            // Restore failed — user can retry
        }
    }

    // MARK: Private

    private func loadProducts() async {
        do {
            products = try await service.loadProducts(for: productIDs)
        } catch {
            // Products unavailable — paywall will show disabled state
        }
    }

    private func refreshAccess() async {
        var found = false
        for await productID in service.currentEntitlementProductIDs() {
            if productIDs.contains(productID) {
                found = true
            }
        }
        hasProAccess = found
    }

    private func listenForTransactions() async {
        for await productID in service.transactionUpdateProductIDs() {
            if productIDs.contains(productID) {
                await refreshAccess()
            }
        }
    }
}
