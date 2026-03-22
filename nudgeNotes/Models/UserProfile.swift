import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var onboardingCompleted: Bool
    var isPro: Bool
    var createdAt: Date
    var goals: [String]

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
        self.goals = goals
    }
}
