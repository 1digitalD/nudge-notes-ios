import Foundation
import Observation

enum CSVExportError: Error {
    case proRequired
}

@Observable
final class HistoryNavigationState {
    var selectedLog: DailyLog?

    func select(log: DailyLog) {
        selectedLog = log
    }
}

@Observable
final class HistoryDeletionState {
    var logPendingDeletion: DailyLog?

    var isShowingDeleteConfirmation: Bool {
        logPendingDeletion != nil
    }

    func confirmDelete(for log: DailyLog) {
        logPendingDeletion = log
    }

    func cancelDelete() {
        logPendingDeletion = nil
    }
}

struct MonthlyHistorySummary {
    let loggedDays: Int
    let averageSleepHours: Double
    let averageSteps: Int
}

struct HistoryViewModel {
    let dailyLogs: [DailyLog]
    let profileIsPro: Bool

    func filteredLogs(searchText: String, selectedDay: Date? = nil) -> [DailyLog] {
        let calendar = Calendar.current
        let filteredByDay = dailyLogs.filter { log in
            guard let selectedDay else { return true }
            return calendar.isDate(log.date, inSameDayAs: selectedDay)
        }
        let sorted = filteredByDay.sorted(by: { $0.date > $1.date })
        guard !searchText.isEmpty else { return sorted }
        return sorted.filter { ($0.notes ?? "").localizedCaseInsensitiveContains(searchText) }
    }

    var heatmapByDay: [Date: Int] {
        dailyLogs.reduce(into: [Date: Int]()) { partialResult, log in
            let day = Calendar.current.startOfDay(for: log.date)
            partialResult[day, default: 0] += 1
        }
    }

    func monthlySummary(for month: Date = .now) -> MonthlyHistorySummary {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: month) else {
            return MonthlyHistorySummary(loggedDays: 0, averageSleepHours: 0, averageSteps: 0)
        }

        let monthlyLogs = dailyLogs.filter { interval.contains($0.date) }
        let sleepValues = monthlyLogs.compactMap(\.sleepHours)
        let stepValues = monthlyLogs.compactMap(\.steps)
        let averageSleepHours = sleepValues.isEmpty ? 0 : sleepValues.reduce(0, +) / Double(sleepValues.count)
        let averageSteps = stepValues.isEmpty ? 0 : stepValues.reduce(0, +) / stepValues.count

        return MonthlyHistorySummary(
            loggedDays: monthlyLogs.count,
            averageSleepHours: averageSleepHours,
            averageSteps: averageSteps
        )
    }

    func csvExport() throws -> String {
        guard profileIsPro else {
            throw CSVExportError.proRequired
        }

        let formatter = ISO8601DateFormatter()
        let rows = filteredLogs(searchText: "").map { log -> String in
            let date = formatter.string(from: log.date)
            let sleepHours = log.sleepHours.map { String($0) } ?? ""
            let steps = log.steps.map { String($0) } ?? ""
            let waterGlasses = log.waterGlasses.map { String($0) } ?? ""
            let notes = "\"\((log.notes ?? "").replacingOccurrences(of: "\"", with: "'"))\""
            return [date, sleepHours, steps, waterGlasses, notes].joined(separator: ",")
        }

        return (["date,sleepHours,steps,waterGlasses,notes"] + rows).joined(separator: "\n")
    }
}
