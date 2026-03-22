import XCTest
@testable import nudgeNotes

final class PhotoLogTests: XCTestCase {
    func testPhotoLogStoresMetadata() {
        let data = Data([0x00, 0x01, 0x02])
        let photo = PhotoLog(date: WHRTestData.referenceDate, category: .meal, imageData: data, notes: "Lunch")

        XCTAssertEqual(photo.category, .meal)
        XCTAssertEqual(photo.imageData, data)
        XCTAssertEqual(photo.notes, "Lunch")
    }
}
