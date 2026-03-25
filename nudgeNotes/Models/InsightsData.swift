import SwiftUI

struct WeekData {
    let dateRange: String
    let daysLogged: Int
    let waterGoalHitRate: WaterGoalRate?
    let avgSteps: Int?
    let avgSleepHours: Double?
    let stepGoal: Int?
    let sleepGoal: Double?
    let homeCooked: Int
    let processed: Int
    let takeout: Int
    let totalMeals: Int
    let dailyMoods: [DayMood]
    let topInsight: String?
}

struct WaterGoalRate {
    let hit: Int
    let total: Int
    let percentage: Double
}

struct DayMood {
    let day: String
    let dayLetter: String
    let mood: Int?

    var emoji: String {
        switch mood {
        case 1: return "😢"
        case 2: return "😐"
        case 3: return "🙂"
        case 4: return "😊"
        case 5: return "😄"
        default: return "•"
        }
    }
}

struct MonthData {
    let monthLabel: String
    let daysLogged: Int
    let totalDays: Int
    let consistencyPercentage: Int
    let whrTrend: [WHRDataPoint]
    let weightChange: WeightChange?
    let wins: [String]
    let suggestedFocus: [String]
}

struct WHRDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let whr: Double

    var weekLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

struct WeightChange {
    let pounds: Double

    var formatted: String {
        let sign = pounds < 0 ? "-" : "+"
        return "\(sign)\(String(format: "%.1f", abs(pounds))) lbs"
    }

    var color: Color {
        pounds < 0 ? Color(hex: "#4CAF50") : Color(hex: "#F44336")
    }

    var icon: String {
        pounds < 0 ? "arrow.down.circle.fill" : "arrow.up.circle.fill"
    }
}
