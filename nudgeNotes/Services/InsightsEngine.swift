import Foundation

class InsightsEngine {

    // MARK: - Weekly Insight

    static func generateWeeklyInsight(logs: [DailyLog], settings: UserSettings) -> String? {
        guard !logs.isEmpty else { return nil }

        if let sleepMoodInsight = analyzeSleepMoodCorrelation(logs: logs) {
            return sleepMoodInsight
        }
        if let mealMoodInsight = analyzeMealQualityCorrelation(logs: logs) {
            return mealMoodInsight
        }
        if let waterMoodInsight = analyzeWaterCorrelation(logs: logs, settings: settings) {
            return waterMoodInsight
        }
        if let movementMoodInsight = analyzeMovementCorrelation(logs: logs) {
            return movementMoodInsight
        }

        return nil
    }

    // MARK: - Sleep + Mood

    private static func analyzeSleepMoodCorrelation(logs: [DailyLog]) -> String? {
        let logsWithSleep = logs.filter { $0.sleepHours != nil && $0.mood != nil }
        guard logsWithSleep.count >= 3 else { return nil }

        let goodSleep = logsWithSleep.filter { $0.sleepHours! >= 8 }
        let poorSleep = logsWithSleep.filter { $0.sleepHours! < 7 }
        guard !goodSleep.isEmpty, !poorSleep.isEmpty else { return nil }

        let avgMoodGoodSleep = Double(goodSleep.compactMap(\.mood).reduce(0, +)) / Double(goodSleep.count)
        let avgMoodPoorSleep = Double(poorSleep.compactMap(\.mood).reduce(0, +)) / Double(poorSleep.count)

        if avgMoodGoodSleep > avgMoodPoorSleep {
            let emoji = avgMoodGoodSleep >= 4 ? "😊" : "🙂"
            return "You feel \(emoji) on days with 8+ hours sleep"
        }

        return nil
    }

    // MARK: - Meal Quality + Mood

    private static func analyzeMealQualityCorrelation(logs: [DailyLog]) -> String? {
        let logsWithMeals = logs.filter { !$0.meals.isEmpty && $0.mood != nil }
        guard logsWithMeals.count >= 3 else { return nil }

        let homeCooked = logsWithMeals.filter { log in
            let homeMeals = log.meals.filter { $0.quality == .homeCook }.count
            return homeMeals > log.meals.count / 2
        }

        let processed = logsWithMeals.filter { log in
            log.meals.contains { $0.quality == .packaged }
        }

        guard !homeCooked.isEmpty else { return nil }

        let avgMoodHomeCooked = Double(homeCooked.compactMap(\.mood).reduce(0, +)) / Double(homeCooked.count)

        if avgMoodHomeCooked >= 4 {
            return "Home-cooked meals correlate with better mood"
        }

        if processed.count >= 3 {
            return "You ate processed food \(processed.count) times this week"
        }

        return nil
    }

    // MARK: - Water + Mood

    private static func analyzeWaterCorrelation(logs: [DailyLog], settings: UserSettings) -> String? {
        let goal = settings.waterGoalGlasses
        guard goal > 0 else { return nil }

        let logsWithWater = logs.filter { $0.waterGlasses != nil && $0.mood != nil }
        guard logsWithWater.count >= 3 else { return nil }

        let metGoal = logsWithWater.filter { $0.waterGlasses! >= goal }
        guard !metGoal.isEmpty else { return nil }

        let avgMoodMetGoal = Double(metGoal.compactMap(\.mood).reduce(0, +)) / Double(metGoal.count)

        if avgMoodMetGoal >= 4 {
            return "You feel best on days you hit your water goal"
        }

        return nil
    }

    // MARK: - Movement + Mood

    private static func analyzeMovementCorrelation(logs: [DailyLog]) -> String? {
        let logsWithMovement = logs.filter { ($0.steps ?? 0) > 0 && $0.mood != nil }
        guard logsWithMovement.count >= 3 else { return nil }

        let activeDay = logsWithMovement.filter { ($0.steps ?? 0) >= 8000 }
        guard !activeDay.isEmpty else { return nil }

        let avgMoodActive = Double(activeDay.compactMap(\.mood).reduce(0, +)) / Double(activeDay.count)

        if avgMoodActive >= 4 {
            return "You feel 😊 on days with 8k+ steps"
        }

        return nil
    }

    // MARK: - Monthly Wins

    static func generateMonthlyWins(logs: [DailyLog], weeklyMetrics: [WeeklyMetrics]) -> [String] {
        var wins: [String] = []

        let loggedDays = logs.count
        if loggedDays >= 20 {
            wins.append("\(loggedDays)-day logging consistency")
        }

        if weeklyMetrics.count >= 2,
           let first = weeklyMetrics.last,
           let last = weeklyMetrics.first {
            let change = last.whr - first.whr
            if change < -0.02 {
                wins.append("WHR down \(String(format: "%.2f", abs(change)))")
            }
        }

        let totalMeals = logs.flatMap(\.meals).count
        let homeCookedMeals = logs.flatMap(\.meals).filter { $0.quality == .homeCook }.count
        if totalMeals > 0 {
            let percentage = Int((Double(homeCookedMeals) / Double(totalMeals)) * 100)
            if percentage >= 70 {
                wins.append("Home-cooked \(percentage)% of meals")
            }
        }

        let waterGoalHits = logs.filter { log in
            guard let glasses = log.waterGlasses else { return false }
            return glasses >= 8
        }.count
        if waterGoalHits >= 20 {
            wins.append("Hit water goal \(waterGoalHits) days")
        }

        return wins
    }

    // MARK: - Focus Areas

    static func generateFocusAreas(logs: [DailyLog], settings: UserSettings) -> [String] {
        var focus: [String] = []

        let sleepLogs = logs.compactMap(\.sleepHours)
        if !sleepLogs.isEmpty {
            let avgSleep = sleepLogs.reduce(0, +) / Double(sleepLogs.count)
            if avgSleep < 7.5 {
                focus.append("Aim for 7.5+ hours sleep consistently")
            }
        }

        let processedMeals = logs.flatMap(\.meals).filter { $0.quality == .packaged }.count
        if processedMeals >= 5 {
            focus.append("Reduce processed food to < 3 meals/week")
        }

        let stepsLogs = logs.compactMap(\.steps)
        if !stepsLogs.isEmpty {
            let avgSteps = stepsLogs.reduce(0, +) / stepsLogs.count
            if avgSteps < 8000 {
                focus.append("Target 8k steps daily")
            }
        }

        return focus
    }

    // MARK: - Build WeekData

    static func buildWeekData(logs: [DailyLog], settings: UserSettings) -> WeekData {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekStart = calendar.date(byAdding: .day, value: -6, to: today)!

        let weekLogs = logs.filter {
            let day = calendar.startOfDay(for: $0.date)
            return day >= weekStart && day <= today
        }

        let uniqueDays = Set(weekLogs.map { calendar.startOfDay(for: $0.date) })
        let daysLogged = uniqueDays.count

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        let dateRange = "\(dateFormatter.string(from: weekStart)) – \(dateFormatter.string(from: today))"

        // Water goal hit rate
        let goal = settings.waterGoalGlasses
        let logsWithWater = weekLogs.filter { $0.waterGlasses != nil }
        let waterGoalRate: WaterGoalRate?
        if !logsWithWater.isEmpty, goal > 0 {
            let hit = logsWithWater.filter { $0.waterGlasses! >= goal }.count
            let total = logsWithWater.count
            waterGoalRate = WaterGoalRate(hit: hit, total: total, percentage: total > 0 ? Double(hit) / Double(total) : 0)
        } else {
            waterGoalRate = nil
        }

        // Averages
        let stepsValues = weekLogs.compactMap(\.steps)
        let avgSteps = stepsValues.isEmpty ? nil : stepsValues.reduce(0, +) / stepsValues.count
        let sleepValues = weekLogs.compactMap(\.sleepHours)
        let avgSleep = sleepValues.isEmpty ? nil : sleepValues.reduce(0, +) / Double(sleepValues.count)

        // Meals breakdown
        let allMeals = weekLogs.flatMap(\.meals)
        let homeCooked = allMeals.filter { $0.quality == .homeCook }.count
        let processed = allMeals.filter { $0.quality == .packaged }.count
        let takeout = allMeals.filter { $0.quality == .restaurant }.count

        // Daily moods
        let dayLetters = ["S", "M", "T", "W", "T", "F", "S"]
        var dailyMoods: [DayMood] = []
        for offset in 0..<7 {
            let day = calendar.date(byAdding: .day, value: offset, to: weekStart)!
            let dayStart = calendar.startOfDay(for: day)
            let log = weekLogs.first { calendar.startOfDay(for: $0.date) == dayStart }
            let weekday = calendar.component(.weekday, from: day)
            dailyMoods.append(DayMood(
                day: dateFormatter.string(from: day),
                dayLetter: dayLetters[weekday - 1],
                mood: log?.mood
            ))
        }

        let topInsight = generateWeeklyInsight(logs: weekLogs, settings: settings)

        return WeekData(
            dateRange: dateRange,
            daysLogged: daysLogged,
            waterGoalHitRate: waterGoalRate,
            avgSteps: avgSteps,
            avgSleepHours: avgSleep,
            stepGoal: settings.stepGoalEnabled ? settings.stepGoal : nil,
            sleepGoal: settings.sleepGoalEnabled ? settings.sleepGoalHours : nil,
            homeCooked: homeCooked,
            processed: processed,
            takeout: takeout,
            totalMeals: allMeals.count,
            dailyMoods: dailyMoods,
            topInsight: topInsight
        )
    }

    // MARK: - Build MonthData

    static func buildMonthData(logs: [DailyLog], weeklyMetrics: [WeeklyMetrics], settings: UserSettings) -> MonthData {
        let calendar = Calendar.current
        let now = Date()
        guard let monthInterval = calendar.dateInterval(of: .month, for: now) else {
            return MonthData(monthLabel: "", daysLogged: 0, totalDays: 30, consistencyPercentage: 0, whrTrend: [], weightChange: nil, wins: [], suggestedFocus: [])
        }

        let monthLogs = logs.filter { monthInterval.contains($0.date) }
        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        let daysSoFar = calendar.component(.day, from: now)
        let uniqueDays = Set(monthLogs.map { calendar.startOfDay(for: $0.date) }).count
        let consistency = daysSoFar > 0 ? Int(Double(uniqueDays) / Double(daysSoFar) * 100) : 0

        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM yyyy"
        let monthLabel = monthFormatter.string(from: now)

        // WHR trend from WeeklyMetrics (last 4 weeks)
        let fourWeeksAgo = calendar.date(byAdding: .day, value: -28, to: now)!
        let recentMetrics = weeklyMetrics
            .filter { $0.date >= fourWeeksAgo }
            .sorted { $0.date < $1.date }
        let whrTrend = recentMetrics.map { WHRDataPoint(date: $0.date, whr: $0.whr) }

        // Weight change
        let sortedMetrics = recentMetrics.sorted { $0.date < $1.date }
        let weightChange: WeightChange?
        if sortedMetrics.count >= 2, let first = sortedMetrics.first, let last = sortedMetrics.last {
            weightChange = WeightChange(pounds: last.weight - first.weight)
        } else {
            weightChange = nil
        }

        let wins = generateMonthlyWins(logs: monthLogs, weeklyMetrics: recentMetrics)
        let focus = generateFocusAreas(logs: monthLogs, settings: settings)

        return MonthData(
            monthLabel: monthLabel,
            daysLogged: uniqueDays,
            totalDays: daysInMonth,
            consistencyPercentage: consistency,
            whrTrend: whrTrend,
            weightChange: weightChange,
            wins: wins,
            suggestedFocus: focus
        )
    }
}
