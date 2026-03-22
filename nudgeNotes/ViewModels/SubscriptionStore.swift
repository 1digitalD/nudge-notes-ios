import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class SubscriptionStore {
    private let service: any SubscriptionServiceProtocol
    private let profile: UserProfile

    var products: [StoreProduct] = []
    var selectedPlan: SubscriptionPlan = .yearly
    var isLoading = false
    var statusMessage: String?

    init(
        service: any SubscriptionServiceProtocol = StoreKitSubscriptionService(),
        profile: UserProfile
    ) {
        self.service = service
        self.profile = profile
    }

    func loadProducts(modelContext: ModelContext? = nil) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let loadedProducts = try await service.loadProducts()
            products = loadedProducts.sorted { lhs, rhs in
                sortRank(for: lhs) < sortRank(for: rhs)
            }
            if let firstPlan = products.compactMap(\.plan).first {
                selectedPlan = firstPlan
            }

            profile.isPro = try await service.refreshEntitlements()
            try? modelContext?.save()
        } catch {
            statusMessage = "Unable to load Pro options right now."
        }
    }

    func purchaseSelectedPlan(modelContext: ModelContext? = nil) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await service.purchase(productID: selectedPlan.productID)
            apply(result: result, modelContext: modelContext)
        } catch {
            statusMessage = "Purchase failed. Please try again."
        }
    }

    func restorePurchases(modelContext: ModelContext? = nil) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await service.restorePurchases()
            apply(result: result, modelContext: modelContext)
        } catch {
            statusMessage = "Restore failed. Please try again."
        }
    }

    private func apply(result: SubscriptionResult, modelContext: ModelContext?) {
        switch result {
        case .success(let isActiveSubscriber):
            profile.isPro = isActiveSubscriber
            statusMessage = isActiveSubscriber ? "Pro unlocked." : "Purchase completed."
        case .restored(let isActiveSubscriber):
            profile.isPro = isActiveSubscriber
            statusMessage = isActiveSubscriber ? "Purchases restored." : "No active Pro subscription found."
        case .pending:
            statusMessage = "Purchase is pending approval."
        case .cancelled:
            statusMessage = "Purchase cancelled."
        }

        try? modelContext?.save()
    }

    private func sortRank(for product: StoreProduct) -> Int {
        switch product.plan {
        case .yearly:
            return 0
        case .monthly:
            return 1
        case nil:
            return 2
        }
    }
}
