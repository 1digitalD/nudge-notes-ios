import XCTest
@testable import nudgeNotes

@MainActor
final class SubscriptionStoreTests: XCTestCase {
    func testLoadProductsSortsYearlyBeforeMonthlyAndKeepsProDisabledWithoutEntitlement() async {
        let service = MockSubscriptionService(
            products: [
                StoreProduct(id: SubscriptionPlan.monthly.productID, displayName: "Monthly", displayPrice: "$4.99", subscriptionPeriod: "month"),
                StoreProduct(id: SubscriptionPlan.yearly.productID, displayName: "Yearly", displayPrice: "$39.99", subscriptionPeriod: "year")
            ],
            entitlementActive: false
        )
        let profile = UserProfile()
        let store = SubscriptionStore(service: service, profile: profile)

        await store.loadProducts()

        XCTAssertEqual(store.products.map(\.id), [SubscriptionPlan.yearly.productID, SubscriptionPlan.monthly.productID])
        XCTAssertEqual(store.selectedPlan, .yearly)
        XCTAssertFalse(profile.isPro)
        XCTAssertNil(store.statusMessage)
    }

    func testPurchaseActivatesProAndSetsSuccessMessage() async {
        let service = MockSubscriptionService(
            products: [StoreProduct(id: SubscriptionPlan.yearly.productID, displayName: "Yearly", displayPrice: "$39.99", subscriptionPeriod: "year")],
            purchaseResults: [.success(isActiveSubscriber: true)]
        )
        let profile = UserProfile()
        let store = SubscriptionStore(service: service, profile: profile)
        await store.loadProducts()

        await store.purchaseSelectedPlan()

        XCTAssertTrue(profile.isPro)
        let purchasedProductIDs = await service.purchasedProductIDs
        XCTAssertEqual(purchasedProductIDs, [SubscriptionPlan.yearly.productID])
        XCTAssertEqual(store.statusMessage, "Pro unlocked.")
    }

    func testRestorePurchasesUpdatesProfileAndMessage() async {
        let service = MockSubscriptionService(
            products: [],
            restoreResult: .restored(isActiveSubscriber: true)
        )
        let profile = UserProfile()
        let store = SubscriptionStore(service: service, profile: profile)

        await store.restorePurchases()

        XCTAssertTrue(profile.isPro)
        XCTAssertEqual(store.statusMessage, "Purchases restored.")
        let restoreCallCount = await service.restoreCallCount
        XCTAssertEqual(restoreCallCount, 1)
    }

    func testCancelledPurchaseDoesNotUnlockPro() async {
        let service = MockSubscriptionService(
            products: [StoreProduct(id: SubscriptionPlan.monthly.productID, displayName: "Monthly", displayPrice: "$4.99", subscriptionPeriod: "month")],
            purchaseResults: [.cancelled]
        )
        let profile = UserProfile()
        let store = SubscriptionStore(service: service, profile: profile)
        await store.loadProducts()
        store.selectedPlan = .monthly

        await store.purchaseSelectedPlan()

        XCTAssertFalse(profile.isPro)
        XCTAssertEqual(store.statusMessage, "Purchase cancelled.")
    }
}

private actor MockSubscriptionService: SubscriptionServiceProtocol {
    let products: [StoreProduct]
    let entitlementActive: Bool
    var purchaseResults: [SubscriptionResult]
    let restoreResult: SubscriptionResult
    private(set) var purchasedProductIDs: [String] = []
    private(set) var restoreCallCount = 0

    init(
        products: [StoreProduct],
        entitlementActive: Bool = false,
        purchaseResults: [SubscriptionResult] = [.success(isActiveSubscriber: false)],
        restoreResult: SubscriptionResult = .restored(isActiveSubscriber: false)
    ) {
        self.products = products
        self.entitlementActive = entitlementActive
        self.purchaseResults = purchaseResults
        self.restoreResult = restoreResult
    }

    func loadProducts() async throws -> [StoreProduct] {
        products
    }

    func purchase(productID: String) async throws -> SubscriptionResult {
        purchasedProductIDs.append(productID)
        return purchaseResults.isEmpty ? .success(isActiveSubscriber: false) : purchaseResults.removeFirst()
    }

    func restorePurchases() async throws -> SubscriptionResult {
        restoreCallCount += 1
        return restoreResult
    }

    func refreshEntitlements() async throws -> Bool {
        entitlementActive
    }
}
