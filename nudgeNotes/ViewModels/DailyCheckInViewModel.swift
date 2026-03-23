import Foundation
import Observation
import SwiftData

struct PhotoDraft: Identifiable {
    let id = UUID()
    let data: Data
    let category: PhotoCategory
    let notes: String?
}

@Observable
final class DailyCheckInViewModel {
    let date: Date
    private let existingLog: DailyLog?
    var sleepHoursText = ""
    var sleepQuality = 3
    var movement = false
    var stepsText = ""
    var waterGlassesText = ""
    var nutritionQuality = 3
    var mood = 3
    var stress = 3
    var notes = ""
    var photos: [PhotoDraft] = []
    var meals: [MealLog] = []

    var isEditMode: Bool {
        existingLog != nil
    }

    init(date: Date, existingLog: DailyLog? = nil) {
        self.date = date
        self.existingLog = existingLog

        guard let existingLog else { return }
        sleepHoursText = existingLog.sleepHours.map(Self.formatNumber) ?? ""
        sleepQuality = existingLog.sleepQuality ?? 3
        movement = existingLog.movement ?? false
        stepsText = existingLog.steps.map(String.init) ?? ""
        waterGlassesText = existingLog.waterGlasses.map(String.init) ?? ""
        nutritionQuality = existingLog.nutritionQuality ?? 3
        mood = existingLog.mood ?? 3
        stress = existingLog.stress ?? 3
        notes = existingLog.notes ?? ""
        meals = existingLog.meals.sorted(by: { $0.timestamp < $1.timestamp })
    }

    func addPhoto(data: Data, category: PhotoCategory, notes: String?) {
        photos.append(PhotoDraft(data: data, category: category, notes: notes))
    }

    @discardableResult
    func addNewMeal() -> MealLog {
        let meal = MealLog(timestamp: Date(), mealType: .breakfast)
        meals.append(meal)
        meals.sort(by: { $0.timestamp < $1.timestamp })
        return meal
    }

    func deleteMeal(at offsets: IndexSet) {
        meals.remove(atOffsets: offsets)
    }

    func calculateFastingWindow(modelContext: ModelContext) -> TimeInterval? {
        guard let firstMeal = meals.min(by: { $0.timestamp < $1.timestamp }) else {
            return nil
        }

        guard let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: date) else {
            return nil
        }

        let previousDayStart = Calendar.current.startOfDay(for: previousDay)
        let nextDayStart = Calendar.current.date(byAdding: .day, value: 1, to: previousDayStart) ?? previousDayStart
        let descriptor = FetchDescriptor<DailyLog>(
            predicate: #Predicate<DailyLog> { log in
                log.date >= previousDayStart && log.date < nextDayStart
            }
        )

        guard
            let previousDayLog = try? modelContext.fetch(descriptor).first,
            let lastMeal = previousDayLog.meals.max(by: { $0.timestamp < $1.timestamp })
        else {
            return nil
        }

        return firstMeal.timestamp.timeIntervalSince(lastMeal.timestamp)
    }

    func fastingWindowHours(modelContext: ModelContext) -> Double? {
        guard let fastingInterval = calculateFastingWindow(modelContext: modelContext) else {
            return nil
        }

        return fastingInterval / 3_600
    }

    @discardableResult
    func save(in context: ModelContext) throws -> DailyLog {
        let log = existingLog ?? DailyLog(date: date)

        let existingMeals = log.meals
        let retainedMealIDs = Set(meals.map(\.id))
        for meal in existingMeals where !retainedMealIDs.contains(meal.id) {
            context.delete(meal)
        }

        log.date = date
        log.sleepHours = Double(sleepHoursText)
        log.sleepQuality = sleepQuality
        log.movement = movement
        log.steps = Int(stepsText)
        log.waterGlasses = Int(waterGlassesText)
        log.nutritionQuality = nutritionQuality
        log.mood = mood
        log.stress = stress
        log.notes = notes.nilIfEmpty
        log.updatedAt = Date()

        let attachedPhotos = existingLog == nil ? photos.map { draft in
            PhotoLog(date: date, category: draft.category, imageData: draft.data, notes: draft.notes)
        } : log.photos
        attachedPhotos.forEach { $0.dailyLog = log }
        log.photos = attachedPhotos

        meals.forEach {
            $0.dailyLog = log
            $0.updatedAt = Date()
        }
        log.meals = meals.sorted(by: { $0.timestamp < $1.timestamp })

        if existingLog == nil {
            context.insert(log)
        }
        try context.save()
        return log
    }

    private static func formatNumber(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }

        return String(value)
    }
}

private extension String {
    var nilIfEmpty: String? {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self
    }
}
