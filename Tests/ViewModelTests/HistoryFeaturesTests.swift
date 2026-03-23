import XCTest
@testable import nudgeNotes

final class HistoryFeaturesTests: XCTestCase {
    func testPendingDeleteConfirmationRequiresSelection() {
        let viewModel = HistoryDeletionState()

        XCTAssertNil(viewModel.logPendingDeletion)
        XCTAssertFalse(viewModel.isShowingDeleteConfirmation)

        let log = DailyLog(date: WHRTestData.referenceDate, notes: "Delete me")
        viewModel.confirmDelete(for: log)

        XCTAssertTrue(viewModel.isShowingDeleteConfirmation)
        XCTAssertTrue(viewModel.logPendingDeletion === log)

        viewModel.cancelDelete()
        XCTAssertFalse(viewModel.isShowingDeleteConfirmation)
        XCTAssertNil(viewModel.logPendingDeletion)
    }

    func testSelectingLogForEditReturnsSameLog() {
        let log = DailyLog(date: WHRTestData.referenceDate, notes: "Editable")
        let coordinator = HistoryNavigationState()

        coordinator.select(log: log)

        XCTAssertTrue(coordinator.selectedLog === log)
    }

    func testHistorySearchFiltersByNotes() {
        let morningLog = DailyLog(date: WHRTestData.referenceDate, notes: "Morning walk")
        let eveningLog = DailyLog(date: WHRTestData.referenceDate.addingTimeInterval(86_400), notes: "Quiet evening")
        let viewModel = HistoryViewModel(dailyLogs: [morningLog, eveningLog], profileIsPro: false)

        let results = viewModel.filteredLogs(searchText: "walk")

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.notes, "Morning walk")
    }

    func testHeatmapCountsLogsByDay() {
        let firstDay = Calendar.current.startOfDay(for: WHRTestData.referenceDate)
        let logs = [
            DailyLog(date: firstDay, notes: "A"),
            DailyLog(date: firstDay.addingTimeInterval(1_000), notes: "B"),
            DailyLog(date: firstDay.addingTimeInterval(86_400), notes: "C")
        ]
        let viewModel = HistoryViewModel(dailyLogs: logs, profileIsPro: false)

        let heatmap = viewModel.heatmapByDay

        XCTAssertEqual(heatmap[firstDay], 2)
        XCTAssertEqual(heatmap[firstDay.addingTimeInterval(86_400)], 1)
    }

    func testCSVExportRequiresProAndIncludesHeader() throws {
        let logs = [DailyLog(date: WHRTestData.referenceDate, sleepHours: 7.5, notes: "Steady")]
        let lockedViewModel = HistoryViewModel(dailyLogs: logs, profileIsPro: false)
        XCTAssertThrowsError(try lockedViewModel.csvExport())

        let proViewModel = HistoryViewModel(dailyLogs: logs, profileIsPro: true)
        let csv = try proViewModel.csvExport()

        XCTAssertTrue(csv.contains("date,sleepHours,steps,waterGlasses,notes"))
        XCTAssertTrue(csv.contains("Steady"))
    }

    func testHistoryFiltersBySelectedDay() {
        let calendar = Calendar.current
        let selectedDay = calendar.startOfDay(for: WHRTestData.referenceDate)
        let logs = [
            DailyLog(date: selectedDay.addingTimeInterval(600), notes: "Morning"),
            DailyLog(date: selectedDay.addingTimeInterval(86_400), notes: "Tomorrow")
        ]
        let viewModel = HistoryViewModel(dailyLogs: logs, profileIsPro: false)

        let results = viewModel.filteredLogs(searchText: "", selectedDay: selectedDay)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.notes, "Morning")
    }

    func testMonthlySummaryAveragesValuesForCurrentMonth() {
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: WHRTestData.referenceDate)) ?? WHRTestData.referenceDate
        let logs = [
            DailyLog(date: monthStart.addingTimeInterval(3_600), sleepHours: 7, steps: 8_000),
            DailyLog(date: monthStart.addingTimeInterval(86_400), sleepHours: 8, steps: 10_000),
            DailyLog(date: monthStart.addingTimeInterval(40 * 86_400), sleepHours: 6, steps: 4_000)
        ]
        let viewModel = HistoryViewModel(dailyLogs: logs, profileIsPro: false)

        let summary = viewModel.monthlySummary(for: monthStart)

        XCTAssertEqual(summary.loggedDays, 2)
        XCTAssertEqual(summary.averageSleepHours, 7.5, accuracy: 0.01)
        XCTAssertEqual(summary.averageSteps, 9_000)
    }
}
