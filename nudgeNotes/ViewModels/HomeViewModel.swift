import Foundation

struct HomeViewModel {
    let dailyLogs: [DailyLog]
    let whrEntries: [WHREntry]
    var weeklyMetrics: [WeeklyMetrics] = []

    var loggedDaysCount: Int {
        Set(dailyLogs.map { Calendar.current.startOfDay(for: $0.date) }).count
    }

    var photoCount: Int {
        dailyLogs.reduce(into: 0) { partialResult, log in
            partialResult += log.photos.count
        }
    }

    var latestWHRText: String {
        // Check both WHREntry and WeeklyMetrics for latest WHR
        let whrFromEntries = whrEntries.sorted(by: { $0.date > $1.date }).first
        let whrFromMetrics = weeklyMetrics.sorted(by: { $0.date > $1.date }).first(where: { $0.whr > 0 })

        // Use whichever is more recent
        if let entry = whrFromEntries, let metrics = whrFromMetrics {
            if entry.date > metrics.date {
                return String(format: "%.2f", entry.ratio)
            } else {
                return String(format: "%.2f", metrics.whr)
            }
        } else if let entry = whrFromEntries {
            return String(format: "%.2f", entry.ratio)
        } else if let metrics = whrFromMetrics {
            return String(format: "%.2f", metrics.whr)
        }
        return "--"
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
