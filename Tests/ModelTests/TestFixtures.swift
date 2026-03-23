import Foundation
@testable import nudgeNotes

enum WHRTestData {
    static let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)
    static let sample1 = WHREntry(date: referenceDate, waist: 85, hip: 95)
    static let healthyFemale = WHREntry(date: referenceDate, waist: 70, hip: 95)
    static let moderateFemale = WHREntry(date: referenceDate, waist: 78, hip: 95)
    static let highFemale = WHREntry(date: referenceDate, waist: 86, hip: 95)
}

enum DailyLogTestData {
    static let sample = DailyLog(
        date: WHRTestData.referenceDate,
        sleepHours: 7.5,
        sleepQuality: 4,
        movement: true,
        steps: 8200,
        waterGlasses: 7,
        nutritionQuality: 4,
        mood: 4,
        stress: 2,
        notes: "Steady day",
        photos: [],
        meals: []
    )
}
