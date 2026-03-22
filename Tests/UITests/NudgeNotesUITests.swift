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

    func testCoreTrackingFlowCreatesDailyLogAndWHREntry() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset-store", "-ui-testing-seed-onboarded", "-ui-testing-use-sample-photo"]
        app.launch()

        XCTAssertTrue(app.staticTexts["home-title"].waitForExistence(timeout: 2))
        app.buttons["check-in-button"].tap()

        let sleepField = app.textFields["sleep-hours-field"]
        sleepField.tap()
        sleepField.typeText("7.5")

        let stepsField = app.textFields["steps-field"]
        stepsField.tap()
        stepsField.typeText("8200")

        let waterField = app.textFields["water-field"]
        waterField.tap()
        waterField.typeText("6")

        app.switches["movement-toggle"].tap()
        app.buttons["save-check-in-button"].tap()

        XCTAssertEqual(app.staticTexts["logged-days-value"].value as? String, "1")

        app.buttons["whr-calculator-button"].tap()
        let waistField = app.textFields["waist-field"]
        waistField.tap()
        waistField.typeText("85")

        let hipField = app.textFields["hip-field"]
        hipField.tap()
        hipField.typeText("95")
        app.buttons["save-whr-button"].tap()

        XCTAssertEqual(app.staticTexts["current-whr-value"].value as? String, "0.89")
    }

    func testHistoryFlowSupportsSearch() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset-store", "-ui-testing-seed-onboarded"]
        app.launch()

        XCTAssertTrue(app.staticTexts["home-title"].waitForExistence(timeout: 2))
        app.buttons["check-in-button"].tap()

        let sleepField = app.textFields["sleep-hours-field"]
        sleepField.tap()
        sleepField.typeText("8")

        app.swipeUp()
        let notesField = app.textFields["notes-field"]
        notesField.tap()
        notesField.typeText("Evening stretch")

        app.buttons["save-check-in-button"].tap()

        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 2))

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 2))
        searchField.tap()
        searchField.typeText("stretch")

        let historyCell = app.buttons["history-log-cell-Evening stretch"]
        XCTAssertTrue(historyCell.waitForExistence(timeout: 2))
        app.keyboards.buttons["search"].tap()
    }

    func testInsightsAndSettingsPromptForProUpgrade() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-reset-store", "-ui-testing-seed-onboarded"]
        app.launch()

        XCTAssertTrue(app.staticTexts["home-title"].waitForExistence(timeout: 2))

        app.tabBars.buttons["Insights"].tap()
        XCTAssertTrue(app.buttons["Unlock Pro Insights"].waitForExistence(timeout: 2))
        app.buttons["Unlock Pro Insights"].tap()
        XCTAssertTrue(app.navigationBars["Nudge Notes Pro"].waitForExistence(timeout: 2))
        app.buttons["Close"].tap()

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.buttons["Upgrade to Pro"].waitForExistence(timeout: 2))
    }
}
