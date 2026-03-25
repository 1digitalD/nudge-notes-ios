import Charts
import SwiftData
import SwiftUI

struct InsightsView: View {
    let profile: UserProfile

    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]
    @Query(sort: \WHREntry.date, order: .reverse) private var whrEntries: [WHREntry]
    @State private var isPresentingUpgrade = false

    private var viewModel: InsightsViewModel {
        InsightsViewModel(dailyLogs: dailyLogs, whrEntries: whrEntries, isPro: profile.isPro)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.canAccessInsights {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            chartCard
                            weeklySummaryCard
                            patternCard
                        }
                        .padding(24)
                    }
                    .background(Color(.systemGroupedBackground))
                } else {
                    lockedState
                }
            }
            .navigationTitle("Insights")
            .sheet(isPresented: $isPresentingUpgrade) {
                ProUpgradeView(profile: profile)
            }
        }
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WHR Trend")
                .font(.title3.weight(.semibold))

            if viewModel.trendPoints.isEmpty {
                Text("Log a WHR check-in to start charting your trend.")
                    .foregroundStyle(.secondary)
            } else {
                Chart(viewModel.trendPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("WHR", point.ratio)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.accentColor)

                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("WHR", point.ratio)
                    )
                    .foregroundStyle(Color.accentColor.opacity(0.16))
                }
                .frame(height: 220)
                .accessibilityLabel("WHR trend chart")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var weeklySummaryCard: some View {
        let summary = viewModel.weeklySummary
        return VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.title3.weight(.semibold))
            summaryRow(title: "Days logged", value: "\(summary.daysLogged)")
            summaryRow(title: "Avg sleep", value: String(format: "%.1f h", summary.averageSleepHours))
            summaryRow(title: "Avg steps", value: "\(summary.averageSteps)")
            summaryRow(title: "Avg water", value: String(format: "%.1f glasses", summary.averageWaterGlasses))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var patternCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Patterns")
                .font(.title3.weight(.semibold))
            Text(patternTitle)
                .font(.headline)
            ForEach(viewModel.nudges, id: \.self) { nudge in
                Text(nudge)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var lockedState: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights")
                .font(.largeTitle.weight(.bold))
                .accessibilityAddTraits(.isHeader)
            Text(viewModel.lockedMessage)
                .foregroundStyle(.secondary)
            Button("Unlock Pro Insights") {
                isPresentingUpgrade = true
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.appAccent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
        .background(Color.appBackground)
    }

    private func summaryRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
    }

    private var patternTitle: String {
        switch viewModel.pattern {
        case .improving:
            return "Improving trend"
        case .declining:
            return "Rising trend"
        case .stable:
            return "Stable trend"
        case .insufficientData:
            return "Not enough data yet"
        }
    }
}
