import XCTest
@testable import nudgeNotes

final class InsightsViewModelTests: XCTestCase {
    func testTrendPointsAreSortedAscending() {
        let later = WHREntry(date: WHRTestData.referenceDate.addingTimeInterval(86_400), waist: 84, hip: 96)
        let earlier = WHREntry(date: WHRTestData.referenceDate, waist: 90, hip: 100)
        let viewModel = InsightsViewModel(
            dailyLogs: [],
            whrEntries: [later, earlier],
            isPro: true
        )

        XCTAssertEqual(viewModel.trendPoints.count, 2)
        XCTAssertEqual(viewModel.trendPoints[0].ratio, 0.9, accuracy: 0.001)
        XCTAssertEqual(viewModel.trendPoints[1].ratio, 0.875, accuracy: 0.001)
    }

    func testWeeklySummaryUsesLastSevenDays() {
        let base = Calendar.current.startOfDay(for: WHRTestData.referenceDate)
        let logs = (0..<8).map { offset in
            DailyLog(
                date: Calendar.current.date(byAdding: .day, value: -offset, to: base) ?? base,
                sleepHours: 7 + Double(offset % 2),
                steps: 7_000 + (offset * 500),
                waterGlasses: 6
            )
        }
        let viewModel = InsightsViewModel(dailyLogs: logs, whrEntries: [], isPro: true, now: base)

        let summary = viewModel.weeklySummary

        XCTAssertEqual(summary.daysLogged, 7)
        XCTAssertEqual(summary.averageWaterGlasses, 6.0, accuracy: 0.01)
    }

    func testPatternDetectionFlagsImprovingTrend() {
        let entries = [
            WHREntry(date: WHRTestData.referenceDate, waist: 98, hip: 100),
            WHREntry(date: WHRTestData.referenceDate.addingTimeInterval(86_400 * 7), waist: 92, hip: 100),
            WHREntry(date: WHRTestData.referenceDate.addingTimeInterval(86_400 * 14), waist: 88, hip: 100)
        ]
        let viewModel = InsightsViewModel(dailyLogs: [], whrEntries: entries, isPro: true)

        XCTAssertEqual(viewModel.pattern, .improving)
        XCTAssertTrue(viewModel.nudges.contains("Your WHR trend is moving in a healthy direction."))
    }

    func testFreeTierExplainsThatInsightsRequirePro() {
        let viewModel = InsightsViewModel(dailyLogs: [], whrEntries: [], isPro: false)

        XCTAssertFalse(viewModel.canAccessInsights)
        XCTAssertEqual(viewModel.lockedMessage, "Insights are part of Nudge Notes Pro.")
    }
}
