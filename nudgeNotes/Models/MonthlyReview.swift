import Foundation
import SwiftData

@Model
final class MonthlyReview {
    @Attribute(.unique) var id: UUID
    var monthStart: Date
    var reflection: String
    var summary: String
    var nextMonthFocus: String

    init(
        id: UUID = UUID(),
        monthStart: Date,
        reflection: String = "",
        summary: String = "",
        nextMonthFocus: String = ""
    ) {
        self.id = id
        self.monthStart = monthStart
        self.reflection = reflection
        self.summary = summary
        self.nextMonthFocus = nextMonthFocus
    }
}
