import XCTest
@testable import nudgeNotes

final class WHREntryTests: XCTestCase {
    func testRatioIsCalculatedFromWaistAndHip() {
        let entry = WHREntry(date: WHRTestData.referenceDate, waist: 81, hip: 90)

        XCTAssertEqual(entry.ratio, 0.9, accuracy: 0.0001)
    }

    func testHealthyCategoryThreshold() {
        XCTAssertEqual(WHRTestData.healthyFemale.category, .healthy)
        XCTAssertTrue(WHRTestData.healthyFemale.isHealthy())
    }

    func testModerateCategoryThreshold() {
        XCTAssertEqual(WHRTestData.moderateFemale.category, .moderate)
        XCTAssertFalse(WHRTestData.moderateFemale.isHealthy())
    }

    func testHighCategoryThreshold() {
        XCTAssertEqual(WHRTestData.highFemale.category, .high)
        XCTAssertFalse(WHRTestData.highFemale.isHealthy())
    }

    func testZeroHipFallsBackToZeroRatio() {
        let entry = WHREntry(date: WHRTestData.referenceDate, waist: 85, hip: 0)

        XCTAssertEqual(entry.ratio, 0)
        XCTAssertEqual(entry.category, .healthy)
    }
}
