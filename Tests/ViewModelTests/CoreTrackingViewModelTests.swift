import SwiftData
import XCTest
@testable import nudgeNotes

final class CoreTrackingViewModelTests: XCTestCase {
    func testHomeViewModelSummarizesLatestWHRAndLogCount() {
        let logs = [
            DailyLog(date: WHRTestData.referenceDate),
            DailyLog(date: WHRTestData.referenceDate.addingTimeInterval(86_400))
        ]
        let entries = [
            WHREntry(date: WHRTestData.referenceDate, waist: 75, hip: 95),
            WHREntry(date: WHRTestData.referenceDate.addingTimeInterval(86_400), waist: 85, hip: 95)
        ]

        let viewModel = HomeViewModel(dailyLogs: logs, whrEntries: entries)

        XCTAssertEqual(viewModel.loggedDaysCount, 2)
        XCTAssertEqual(viewModel.currentStreak, 2)
        XCTAssertEqual(viewModel.latestWHRText, "0.89")
    }

    func testDailyCheckInViewModelSavesLogWithPhoto() throws {
        let container = PersistenceController.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let viewModel = DailyCheckInViewModel(date: WHRTestData.referenceDate)

        viewModel.sleepHoursText = "7.5"
        viewModel.stepsText = "8100"
        viewModel.waterGlassesText = "6"
        viewModel.movement = true
        viewModel.notes = "Steady"
        viewModel.addPhoto(data: Data([0x00, 0x01]), category: .meal, notes: "Lunch")

        let savedLog = try viewModel.save(in: context)

        XCTAssertEqual(savedLog.sleepHours, 7.5)
        XCTAssertEqual(savedLog.steps, 8100)
        XCTAssertEqual(savedLog.waterGlasses, 6)
        XCTAssertEqual(savedLog.photos.count, 1)
        XCTAssertEqual(savedLog.photos.first?.category, .meal)
    }

    func testWHRCalculatorViewModelCalculatesAndSavesEntry() throws {
        let container = PersistenceController.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let viewModel = WHRCalculatorViewModel(date: WHRTestData.referenceDate)

        viewModel.waistText = "85"
        viewModel.hipText = "95"

        XCTAssertEqual(viewModel.ratioText, "0.89")
        XCTAssertEqual(viewModel.category, .high)

        let entry = try viewModel.save(in: context)

        XCTAssertEqual(entry.ratio, 0.8947, accuracy: 0.001)
        XCTAssertEqual(entry.category, .high)
    }
}
