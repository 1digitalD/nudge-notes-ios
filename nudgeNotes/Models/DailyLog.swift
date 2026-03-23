import Foundation
import SwiftData

@Model
final class DailyLog {
    @Attribute(.unique) var id: UUID
    var date: Date
    var sleepHours: Double?
    var sleepQuality: Int?
    var movement: Bool?
    var steps: Int?
    var waterGlasses: Int?
    var nutritionQuality: Int?
    var mood: Int?
    var stress: Int?
    var notes: String?
    @Relationship(deleteRule: .cascade, inverse: \PhotoLog.dailyLog)
    var photos: [PhotoLog]
    @Relationship(deleteRule: .cascade, inverse: \MealLog.dailyLog)
    var meals: [MealLog]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        date: Date,
        sleepHours: Double? = nil,
        sleepQuality: Int? = nil,
        movement: Bool? = nil,
        steps: Int? = nil,
        waterGlasses: Int? = nil,
        nutritionQuality: Int? = nil,
        mood: Int? = nil,
        stress: Int? = nil,
        notes: String? = nil,
        photos: [PhotoLog] = [],
        meals: [MealLog] = []
    ) {
        self.id = id
        self.date = date
        self.sleepHours = sleepHours
        self.sleepQuality = sleepQuality
        self.movement = movement
        self.steps = steps
        self.waterGlasses = waterGlasses
        self.nutritionQuality = nutritionQuality
        self.mood = mood
        self.stress = stress
        self.notes = notes
        self.photos = photos
        self.meals = meals
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
