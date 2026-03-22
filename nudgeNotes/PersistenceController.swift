import Foundation

final class PersistenceController {
    static let shared = PersistenceController()

    var userProfile = UserProfile()
    var whrEntries: [WHREntry] = []
    var dailyLogs: [DailyLog] = []
    var habitEntries: [HabitEntry] = []
    var photoLogs: [PhotoLog] = []

    func reset() {
        userProfile = UserProfile()
        whrEntries = []
        dailyLogs = []
        habitEntries = []
        photoLogs = []
    }
}
