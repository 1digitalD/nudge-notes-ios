import Foundation

enum InsightPattern: String, Equatable {
    case improving
    case declining
    case stable
    case insufficientData
}

struct WHRTrendPoint: Identifiable, Equatable {
    let date: Date
    let ratio: Double

    var id: Date { date }
}

struct WeeklyInsightSummary: Equatable {
    let daysLogged: Int
    let averageSleepHours: Double
    let averageSteps: Int
    let averageWaterGlasses: Double
}

struct InsightsViewModel {
    let dailyLogs: [DailyLog]
    let whrEntries: [WHREntry]
    let isPro: Bool
    let now: Date

    init(dailyLogs: [DailyLog], whrEntries: [WHREntry], isPro: Bool, now: Date = .now) {
        self.dailyLogs = dailyLogs
        self.whrEntries = whrEntries
        self.isPro = isPro
        self.now = now
    }

    var canAccessInsights: Bool {
        isPro
    }

    var lockedMessage: String {
        "Insights are part of Nudge Notes Pro."
    }

    var trendPoints: [WHRTrendPoint] {
        whrEntries
            .sorted(by: { $0.date < $1.date })
            .map { WHRTrendPoint(date: $0.date, ratio: $0.ratio) }
    }

    var weeklySummary: WeeklyInsightSummary {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let weekStart = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let logs = dailyLogs.filter { log in
            let day = calendar.startOfDay(for: log.date)
            return day >= weekStart && day <= today
        }
        let sleepValues = logs.compactMap(\.sleepHours)
        let stepValues = logs.compactMap(\.steps)
        let waterValues = logs.compactMap(\.waterGlasses)

        return WeeklyInsightSummary(
            daysLogged: Set(logs.map { calendar.startOfDay(for: $0.date) }).count,
            averageSleepHours: average(for: sleepValues),
            averageSteps: stepValues.isEmpty ? 0 : stepValues.reduce(0, +) / stepValues.count,
            averageWaterGlasses: average(for: waterValues.map(Double.init))
        )
    }

    var pattern: InsightPattern {
        let points = trendPoints
        guard points.count >= 3, let first = points.first, let last = points.last else {
            return .insufficientData
        }

        let change = last.ratio - first.ratio
        if change <= -0.02 {
            return .improving
        }
        if change >= 0.02 {
            return .declining
        }
        return .stable
    }

    var nudges: [String] {
        switch pattern {
        case .improving:
            return ["Your WHR trend is moving in a healthy direction."]
        case .declining:
            return ["Your recent WHR readings are trending up. A short walk and an early night may help this week."]
        case .stable:
            return ["Your WHR trend is steady. Keep your current routines consistent this week."]
        case .insufficientData:
            return ["Log a few more WHR check-ins this month to unlock trend insights."]
        }
    }

    private func average(for values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
}
