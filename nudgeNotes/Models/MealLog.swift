import Foundation
import SwiftData

@Model
final class MealLog {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var mealType: MealType
    var notes: String?
    var calories: Int?
    var isPackaged: Bool
    @Relationship(deleteRule: .cascade, inverse: \PhotoLog.mealLog)
    var photos: [PhotoLog]
    @Relationship var dailyLog: DailyLog?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        timestamp: Date,
        mealType: MealType,
        notes: String? = nil,
        calories: Int? = nil,
        isPackaged: Bool = false,
        photos: [PhotoLog] = [],
        dailyLog: DailyLog? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.mealType = mealType
        self.notes = notes
        self.calories = calories
        self.isPackaged = isPackaged
        self.photos = photos
        self.dailyLog = dailyLog
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum MealType: String, Codable, CaseIterable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
}
