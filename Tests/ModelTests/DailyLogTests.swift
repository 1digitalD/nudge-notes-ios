import XCTest
@testable import nudgeNotes

final class DailyLogTests: XCTestCase {
    func testDailyLogStoresOptionalInputs() {
        let log = DailyLogTestData.sample

        XCTAssertEqual(log.sleepHours, 7.5)
        XCTAssertEqual(log.sleepQuality, 4)
        XCTAssertEqual(log.steps, 8200)
        XCTAssertEqual(log.notes, "Steady day")
    }

    func testDailyLogDefaultsToNilAndEmptyPhotos() {
        let log = DailyLog(date: WHRTestData.referenceDate)

        XCTAssertNil(log.sleepHours)
        XCTAssertNil(log.movement)
        XCTAssertEqual(log.photos?.count, 0)
    }
}
