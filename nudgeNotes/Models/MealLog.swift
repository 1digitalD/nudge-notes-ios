import Foundation
import SwiftData

enum MealQuality: String, Codable, CaseIterable {
    case homeCook = "Home-cooked"
    case restaurant = "Restaurant/Takeout"
    case packaged = "Packaged/Processed"

    var icon: String {
        switch self {
        case .homeCook: return "🏠"
        case .restaurant: return "🍔"
        case .packaged: return "🏭"
        }
    }

    var shortLabel: String {
        switch self {
        case .homeCook: return "Home"
        case .restaurant: return "Out"
        case .packaged: return "Packaged"
        }
    }
}

@Model
final class MealLog {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var mealType: MealType
    var notes: String?
    var calories: Int?
    var isPackaged: Bool
    var qualityRaw: String?
    @Relationship(deleteRule: .cascade, inverse: \PhotoLog.mealLog)
    var photos: [PhotoLog]
    @Relationship var dailyLog: DailyLog?
    var createdAt: Date
    var updatedAt: Date

    var quality: MealQuality? {
        get { qualityRaw.flatMap { MealQuality(rawValue: $0) } }
        set { qualityRaw = newValue?.rawValue }
    }

    init(
        id: UUID = UUID(),
        timestamp: Date,
        mealType: MealType,
        notes: String? = nil,
        calories: Int? = nil,
        isPackaged: Bool = false,
        quality: MealQuality? = nil,
        photos: [PhotoLog] = [],
        dailyLog: DailyLog? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.mealType = mealType
        self.notes = notes
        self.calories = calories
        self.isPackaged = isPackaged
        self.qualityRaw = quality?.rawValue
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
