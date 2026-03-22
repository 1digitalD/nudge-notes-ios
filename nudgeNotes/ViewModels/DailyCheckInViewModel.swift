import Foundation
import SwiftData

struct PhotoDraft: Identifiable {
    let id = UUID()
    let data: Data
    let category: PhotoCategory
    let notes: String?
}

final class DailyCheckInViewModel {
    let date: Date
    var sleepHoursText = ""
    var sleepQuality = 3
    var movement = false
    var stepsText = ""
    var waterGlassesText = ""
    var nutritionQuality = 3
    var fastingWindowText = ""
    var mood = 3
    var stress = 3
    var notes = ""
    private(set) var photos: [PhotoDraft] = []

    init(date: Date) {
        self.date = date
    }

    func addPhoto(data: Data, category: PhotoCategory, notes: String?) {
        photos.append(PhotoDraft(data: data, category: category, notes: notes))
    }

    @discardableResult
    func save(in context: ModelContext) throws -> DailyLog {
        let log = DailyLog(
            date: date,
            sleepHours: Double(sleepHoursText),
            sleepQuality: sleepQuality,
            movement: movement,
            steps: Int(stepsText),
            waterGlasses: Int(waterGlassesText),
            nutritionQuality: nutritionQuality,
            fastingWindow: Int(fastingWindowText),
            mood: mood,
            stress: stress,
            notes: notes.isEmpty ? nil : notes,
            photos: photos.map { draft in
                PhotoLog(date: date, category: draft.category, imageData: draft.data, notes: draft.notes)
            }
        )

        context.insert(log)
        try context.save()
        return log
    }
}
