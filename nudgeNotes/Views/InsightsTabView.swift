import Charts
import SwiftData
import SwiftUI

struct InsightsTabView: View {
    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]
    @Query(sort: \WeeklyMetrics.date, order: .reverse) private var weeklyMetrics: [WeeklyMetrics]
    @State private var selectedTab = 0

    private let settings = UserSettings()

    private var weekData: WeekData {
        InsightsEngine.buildWeekData(logs: dailyLogs, settings: settings)
    }

    private var monthData: MonthData {
        InsightsEngine.buildMonthData(logs: dailyLogs, weeklyMetrics: weeklyMetrics, settings: settings)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.sectionSpacing) {
                    Picker("Period", selection: $selectedTab) {
                        Text("This Week").tag(0)
                        Text("This Month").tag(1)
                    }
                    .pickerStyle(.segmented)

                    if selectedTab == 0 {
                        WeeklySummaryCard(weekData: weekData)
                    } else {
                        MonthlyProgressCard(monthData: monthData)
                    }
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppSpacing.xxl)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Weekly Summary Card

private struct WeeklySummaryCard: View {
    let weekData: WeekData

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("This Week at a Glance")
                            .font(AppFonts.headline)
                        Text(weekData.dateRange)
                            .font(AppFonts.caption)
                            .foregroundStyle(Color.appTextSecondary)
                    }
                    Spacer()
                }

                Divider()

                // Logging consistency
                HStack {
                    Text("📝 Logged")
                    Spacer()
                    Text("\(weekData.daysLogged) / 7 days")
                        .font(AppFonts.bodyEmphasized)
                    if weekData.daysLogged >= 6 {
                        Text("🎉")
                    }
                }

                // Water goal
                if let waterGoal = weekData.waterGoalHitRate {
                    HStack {
                        Text("💧 Water Goal")
                        Spacer()
                        Text("\(waterGoal.hit) / \(waterGoal.total) days")
                            .font(AppFonts.bodyEmphasized)
                        progressDot(waterGoal.percentage)
                    }
                }

                // Steps average
                if let avgSteps = weekData.avgSteps {
                    HStack {
                        Text("🚶 Avg Steps")
                        Spacer()
                        Text(avgSteps.formatted())
                            .font(AppFonts.bodyEmphasized)
                        if let goal = weekData.stepGoal {
                            progressDot(Double(avgSteps) / Double(goal))
                        }
                    }
                }

                // Sleep average
                if let avgSleep = weekData.avgSleepHours {
                    HStack {
                        Text("😴 Avg Sleep")
                        Spacer()
                        Text(String(format: "%.1fh", avgSleep))
                            .font(AppFonts.bodyEmphasized)
                        if let goal = weekData.sleepGoal {
                            progressDot(avgSleep / goal)
                        }
                    }
                }

                Divider()

                // Meals breakdown
                if weekData.totalMeals > 0 {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("🍽️ Meals")
                            .font(AppFonts.bodyEmphasized)

                        mealTypeRow("🏠 Home-cooked", count: weekData.homeCooked, total: weekData.totalMeals)
                        mealTypeRow("🏭 Processed", count: weekData.processed, total: weekData.totalMeals)
                        mealTypeRow("🍔 Takeout", count: weekData.takeout, total: weekData.totalMeals)
                    }
                }

                // Mood trend
                if !weekData.dailyMoods.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("😊 Mood Trend")
                            .font(AppFonts.bodyEmphasized)

                        HStack(spacing: 4) {
                            ForEach(weekData.dailyMoods, id: \.day) { dayMood in
                                VStack(spacing: 2) {
                                    Text(dayMood.emoji)
                                        .font(.system(size: 20))
                                    Text(dayMood.dayLetter)
                                        .font(AppFonts.caption)
                                        .foregroundStyle(Color.appTextSecondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }

                // Insight
                if let insight = weekData.topInsight {
                    Divider()

                    HStack(alignment: .top, spacing: AppSpacing.sm) {
                        Text("💡")
                            .font(.system(size: 20))
                        Text(insight)
                            .font(AppFonts.caption)
                            .foregroundStyle(Color.appTextSecondary)
                    }
                    .padding(.vertical, AppSpacing.xs)
                    .padding(.horizontal, AppSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.appAccent.opacity(0.1))
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func progressDot(_ percentage: Double) -> some View {
        Circle()
            .fill(percentage >= 0.8 ? Color.appSuccess :
                  percentage >= 0.6 ? Color.appWarning :
                  Color.appDanger)
            .frame(width: 8, height: 8)
    }

    private func mealTypeRow(_ label: String, count: Int, total: Int) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(AppFonts.caption)
            Spacer()
            Text("\(count) / \(total)")
                .font(AppFonts.caption)
                .foregroundStyle(Color.appTextSecondary)
        }
    }
}

// MARK: - Monthly Progress Card

private struct MonthlyProgressCard: View {
    let monthData: MonthData

    var body: some View {
        VStack(spacing: AppSpacing.sectionSpacing) {
            // Header
            AppCard {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("\(monthData.monthLabel) Summary")
                        .font(AppFonts.headline)

                    HStack {
                        Text("Logged: \(monthData.daysLogged) / \(monthData.totalDays) days")
                            .font(AppFonts.body)
                        Spacer()
                        Text("\(monthData.consistencyPercentage)%")
                            .font(AppFonts.bodyEmphasized)
                            .foregroundStyle(Color.appAccent)
                    }
                }
            }

            // WHR Trend
            if !monthData.whrTrend.isEmpty {
                AppCard {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("WHR Trend")
                            .font(AppFonts.headline)

                        WHRLineChart(dataPoints: monthData.whrTrend)
                            .frame(height: 150)

                        if let first = monthData.whrTrend.first, let last = monthData.whrTrend.last {
                            let change = last.whr - first.whr
                            HStack {
                                Text("Change:")
                                    .font(AppFonts.caption)
                                    .foregroundStyle(Color.appTextSecondary)
                                Text(String(format: "%.2f", change))
                                    .font(AppFonts.bodyEmphasized)
                                    .foregroundStyle(change < 0 ? Color.appSuccess : Color.appDanger)
                                if change < 0 {
                                    Text("↓")
                                        .foregroundStyle(Color.appSuccess)
                                } else if change > 0 {
                                    Text("↑")
                                        .foregroundStyle(Color.appDanger)
                                }
                                Spacer()
                            }
                        }
                    }
                }
            }

            // Weight change
            if let weightChange = monthData.weightChange {
                AppCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Weight Change")
                                .font(AppFonts.caption)
                                .foregroundStyle(Color.appTextSecondary)
                            Text(weightChange.formatted)
                                .font(AppFonts.headline)
                                .foregroundStyle(weightChange.color)
                        }
                        Spacer()
                        Image(systemName: weightChange.icon)
                            .font(.system(size: 32))
                            .foregroundStyle(weightChange.color)
                    }
                }
            }

            // Wins
            if !monthData.wins.isEmpty {
                AppCard {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("🏆 This Month's Wins")
                            .font(AppFonts.headline)

                        Divider()

                        ForEach(monthData.wins, id: \.self) { win in
                            HStack(alignment: .top, spacing: AppSpacing.sm) {
                                Text("•")
                                    .font(AppFonts.body)
                                Text(win)
                                    .font(AppFonts.body)
                            }
                        }
                    }
                }
            }

            // Next month focus
            if !monthData.suggestedFocus.isEmpty {
                AppCard {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("🎯 Next Month Focus")
                            .font(AppFonts.headline)

                        Divider()

                        ForEach(monthData.suggestedFocus, id: \.self) { focus in
                            HStack(alignment: .top, spacing: AppSpacing.sm) {
                                Text("→")
                                    .font(AppFonts.body)
                                Text(focus)
                                    .font(AppFonts.body)
                            }
                        }
                    }
                }
            }

            // Empty state
            if monthData.daysLogged == 0 {
                AppCard {
                    VStack(spacing: AppSpacing.md) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.appTextSecondary)
                        Text("Start logging to see monthly insights")
                            .font(AppFonts.body)
                            .foregroundStyle(Color.appTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.lg)
                }
            }
        }
    }
}
