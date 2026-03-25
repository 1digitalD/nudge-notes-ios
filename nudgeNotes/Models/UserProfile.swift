import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var onboardingCompleted: Bool
    var isPro: Bool
    var createdAt: Date
    private var goalsStorage: String?

    // Profile fields for onboarding
    var name: String?
    var weight: Double?
    var heightFeet: Int?
    var heightInches: Int?

    init(
        id: UUID = UUID(),
        onboardingCompleted: Bool = false,
        isPro: Bool = false,
        createdAt: Date = .now,
        goals: [String] = [],
        name: String? = nil,
        weight: Double? = nil,
        heightFeet: Int? = nil,
        heightInches: Int? = nil
    ) {
        self.id = id
        self.onboardingCompleted = onboardingCompleted
        self.isPro = isPro
        self.createdAt = createdAt
        self.goalsStorage = goals.joined(separator: "|")
        self.name = name
        self.weight = weight
        self.heightFeet = heightFeet
        self.heightInches = heightInches
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
