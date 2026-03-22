import Foundation

struct HomeViewModel {
    let dailyLogs: [DailyLog]
    let whrEntries: [WHREntry]

    var loggedDaysCount: Int {
        Set(dailyLogs.map { Calendar.current.startOfDay(for: $0.date) }).count
    }

    var photoCount: Int {
        dailyLogs.reduce(into: 0) { partialResult, log in
            partialResult += log.photos.count
        }
    }

    var latestWHRText: String {
        guard let latest = whrEntries.sorted(by: { $0.date > $1.date }).first else {
            return "--"
        }
        return String(format: "%.2f", latest.ratio)
    }

    var currentStreak: Int {
        let days = Set(dailyLogs.map { Calendar.current.startOfDay(for: $0.date) })
        guard !days.isEmpty else { return 0 }

        var streak = 0
        var current = Calendar.current.startOfDay(for: dailyLogs.map(\.date).max() ?? .now)
        while days.contains(current) {
            streak += 1
            guard let previous = Calendar.current.date(byAdding: .day, value: -1, to: current) else {
                break
            }
            current = previous
        }
        return streak
    }
}
