import Foundation

final class DailyLog {
    var id: UUID
    var date: Date
    var sleepHours: Double?
    var sleepQuality: Int?
    var movement: Bool?
    var steps: Int?
    var waterGlasses: Int?
    var nutritionQuality: Int?
    var fastingWindow: Int?
    var mood: Int?
    var stress: Int?
    var notes: String?
    var photos: [PhotoLog]?

    init(
        id: UUID = UUID(),
        date: Date,
        sleepHours: Double? = nil,
        sleepQuality: Int? = nil,
        movement: Bool? = nil,
        steps: Int? = nil,
        waterGlasses: Int? = nil,
        nutritionQuality: Int? = nil,
        fastingWindow: Int? = nil,
        mood: Int? = nil,
        stress: Int? = nil,
        notes: String? = nil,
        photos: [PhotoLog]? = []
    ) {
        self.id = id
        self.date = date
        self.sleepHours = sleepHours
        self.sleepQuality = sleepQuality
        self.movement = movement
        self.steps = steps
        self.waterGlasses = waterGlasses
        self.nutritionQuality = nutritionQuality
        self.fastingWindow = fastingWindow
        self.mood = mood
        self.stress = stress
        self.notes = notes
        self.photos = photos
    }
}
