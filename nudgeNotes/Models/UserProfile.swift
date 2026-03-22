import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var onboardingCompleted: Bool
    var isPro: Bool
    var createdAt: Date
    private var goalsStorage: String?

    init(
        id: UUID = UUID(),
        onboardingCompleted: Bool = false,
        isPro: Bool = false,
        createdAt: Date = .now,
        goals: [String] = []
    ) {
        self.id = id
        self.onboardingCompleted = onboardingCompleted
        self.isPro = isPro
        self.createdAt = createdAt
        self.goalsStorage = goals.joined(separator: "|")
    }

    var goals: [String] {
        get {
            guard let goalsStorage, !goalsStorage.isEmpty else { return [] }
            return goalsStorage.split(separator: "|").map(String.init)
        }
        set {
            goalsStorage = newValue.joined(separator: "|")
        }
    }
}
