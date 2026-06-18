import Foundation
import StoreKit
import Observation

@Observable
@MainActor
final class StoreKitService {
    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []
    var isLoading = false
    var errorMessage: String?

    let productIDs: [String] = [
        "com.chickfocus.pro.monthly",
        "com.chickfocus.pro.yearly",
        "com.chickfocus.pro.lifetime",
        "com.chickfocus.pet.bird",
        "com.chickfocus.pet.hare",
        "com.chickfocus.pet.fish"
    ]

    var isProUser: Bool {
        purchasedProductIDs.contains("com.chickfocus.pro.yearly") ||
        purchasedProductIDs.contains("com.chickfocus.pro.monthly") ||
        purchasedProductIDs.contains("com.chickfocus.pro.lifetime")
    }

    private var transactionListener: Task<Void, Never>?

    init() {
        transactionListener = listenForTransactions()
        Task { await refreshPurchasedProducts() }
    }

//    deinit {
//        transactionListener?.cancel()
//    }

    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            products = []
            return
        }
        #endif

        do {
            products = try await Product.products(for: productIDs)
                .sorted { $0.price < $1.price }
        } catch {
            errorMessage = error.localizedDescription
            products = []
        }
    }

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await refreshPurchasedProducts()
            return true
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
        await refreshPurchasedProducts()
    }

    func hasPurchased(petType: PetType) -> Bool {
        if !petType.isLocked { return true }
        if isProUser { return true }
        guard let productID = petType.productID else { return false }
        return purchasedProductIDs.contains(productID)
    }

    func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { continue }
                if let transaction = try? self.checkVerified(result) {
                    await transaction.finish()
                    await self.refreshPurchasedProducts()
                }
            }
        }
    }

    func refreshPurchasedProducts() async {
        var purchased: Set<String> = []

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                purchased.insert(transaction.productID)
            }
        }

        purchasedProductIDs = purchased
    }

    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    enum StoreError: Error {
        case failedVerification
    }

    var subscriptionProducts: [Product] {
        products.filter { $0.id.contains("pro") }
    }

    var petProducts: [Product] {
        products.filter { $0.id.contains("pet") }
    }
}

#if DEBUG
extension StoreKitService {
    static var preview: StoreKitService {
        let service = StoreKitService()
        return service
    }

    func enableMockPro() {
        purchasedProductIDs.insert("com.chickfocus.pro.yearly")
    }
}
#endif
