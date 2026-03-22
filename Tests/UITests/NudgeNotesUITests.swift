import XCTest

final class NudgeNotesUITests: XCTestCase {
    func testOnboardingFlowPersistsAcrossRelaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset-store", "-ui-testing-mock-permissions"]
        app.launch()

        XCTAssertTrue(app.staticTexts["welcome-title"].waitForExistence(timeout: 2))
        app.buttons["welcome-continue-button"].tap()

        XCTAssertTrue(app.staticTexts["explainer-title"].waitForExistence(timeout: 2))
        app.buttons["explainer-continue-button"].tap()

        XCTAssertTrue(app.staticTexts["goal-selection-title"].waitForExistence(timeout: 2))
        app.buttons["goal-option-Sleep"].tap()
        app.buttons["goal-option-Movement"].tap()
        app.buttons["goals-continue-button"].tap()

        XCTAssertTrue(app.staticTexts["permissions-title"].waitForExistence(timeout: 2))
        app.buttons["photo-permission-button"].tap()
        app.buttons["notification-permission-button"].tap()
        app.buttons["permissions-continue-button"].tap()

        XCTAssertTrue(app.staticTexts["completion-title"].waitForExistence(timeout: 2))
        app.buttons["finish-onboarding-button"].tap()

        XCTAssertTrue(app.staticTexts["home-title"].waitForExistence(timeout: 2))

        app.terminate()
        app.launchArguments = ["-ui-testing-mock-permissions"]
        app.launch()

        XCTAssertTrue(app.staticTexts["home-title"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["welcome-title"].exists)
    }
}
