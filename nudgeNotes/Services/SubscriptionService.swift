import Foundation
import StoreKit

enum SubscriptionPlan: String, CaseIterable, Identifiable {
    case monthly
    case yearly

    var id: String { rawValue }

    var productID: String {
        switch self {
        case .monthly:
            return "com.henkanhacks.nudgenotes.pro.monthly"
        case .yearly:
            return "com.henkanhacks.nudgenotes.pro.yearly"
        }
    }

    var title: String {
        switch self {
        case .monthly:
            return "Monthly"
        case .yearly:
            return "Yearly"
        }
    }

    var subtitle: String {
        switch self {
        case .monthly:
            return "$4.99 billed every month"
        case .yearly:
            return "$39.99 billed every year"
        }
    }
}

struct StoreProduct: Equatable, Sendable, Identifiable {
    let id: String
    let displayName: String
    let displayPrice: String
    let subscriptionPeriod: String

    var plan: SubscriptionPlan? {
        SubscriptionPlan.allCases.first(where: { $0.productID == id })
    }
}

enum SubscriptionResult: Equatable, Sendable {
    case success(isActiveSubscriber: Bool)
    case restored(isActiveSubscriber: Bool)
    case pending
    case cancelled
}

protocol SubscriptionServiceProtocol: Sendable {
    func loadProducts() async throws -> [StoreProduct]
    func purchase(productID: String) async throws -> SubscriptionResult
    func restorePurchases() async throws -> SubscriptionResult
    func refreshEntitlements() async throws -> Bool
}

struct StoreKitSubscriptionService: SubscriptionServiceProtocol {
    private let productIDs = Set(SubscriptionPlan.allCases.map(\.productID))

    func loadProducts() async throws -> [StoreProduct] {
        let products = try await Product.products(for: Array(productIDs))
        return products.map { product in
            StoreProduct(
                id: product.id,
                displayName: product.displayName,
                displayPrice: product.displayPrice,
                subscriptionPeriod: subscriptionPeriodLabel(for: product.subscription?.subscriptionPeriod)
            )
        }
    }

    func purchase(productID: String) async throws -> SubscriptionResult {
        let products = try await Product.products(for: [productID])
        guard let product = products.first else {
            return .cancelled
        }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            return .success(isActiveSubscriber: true)
        case .userCancelled:
            return .cancelled
        case .pending:
            return .pending
        @unknown default:
            return .cancelled
        }
    }

    func restorePurchases() async throws -> SubscriptionResult {
        try await AppStore.sync()
        return .restored(isActiveSubscriber: try await refreshEntitlements())
    }

    func refreshEntitlements() async throws -> Bool {
        for await result in Transaction.currentEntitlements {
            let transaction = try checkVerified(result)
            if productIDs.contains(transaction.productID) {
                return true
            }
        }
        return false
    }

    private func subscriptionPeriodLabel(for period: Product.SubscriptionPeriod?) -> String {
        guard let period else { return "" }
        switch period.unit {
        case .day:
            return period.value == 1 ? "day" : "\(period.value) days"
        case .week:
            return period.value == 1 ? "week" : "\(period.value) weeks"
        case .month:
            return period.value == 1 ? "month" : "\(period.value) months"
        case .year:
            return period.value == 1 ? "year" : "\(period.value) years"
        @unknown default:
            return ""
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified(_, let error):
            throw error
        }
    }
}
