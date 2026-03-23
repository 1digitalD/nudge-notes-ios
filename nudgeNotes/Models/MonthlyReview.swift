import Foundation
import SwiftData

@Model
final class MonthlyReview {
    @Attribute(.unique) var id: UUID
    var month: Date
    var wentWell: String
    var challenges: String
    var changeForNextMonth: String
    var createdAt: Date
    var updatedAt: Date

    init(
        month: Date,
        wentWell: String = "",
        challenges: String = "",
        changeForNextMonth: String = ""
    ) {
        self.id = UUID()
        self.month = month
        self.wentWell = wentWell
        self.challenges = challenges
        self.changeForNextMonth = changeForNextMonth
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
