import XCTest

final class NudgeNotesUITests: XCTestCase {
    func testAppLaunches() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["nudge Notes"].waitForExistence(timeout: 1))
    }
}
