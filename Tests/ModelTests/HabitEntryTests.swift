import XCTest
@testable import nudgeNotes

final class HabitEntryTests: XCTestCase {
    func testBinaryHabitStartsIncomplete() {
        let entry = HabitEntry(name: "Walk outside", type: .binary, date: WHRTestData.referenceDate)

        XCTAssertFalse(entry.completed)
        XCTAssertNil(entry.value)
    }

    func testNumericHabitStoresValue() {
        let entry = HabitEntry(name: "Water", type: .numeric, value: 8, completed: true, date: WHRTestData.referenceDate)

        XCTAssertEqual(entry.value, 8)
        XCTAssertTrue(entry.completed)
    }
}
