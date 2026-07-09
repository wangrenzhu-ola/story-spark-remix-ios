import XCTest

final class StorySparkRemixUITests: XCTestCase {
    @MainActor
    func testCreateEditSaveDeleteConfirmationFlow() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        app.tabBars.buttons["Sprint"].tap()

        let bodyEditor = app.textViews["microdraft-body-editor"]
        XCTAssertTrue(bodyEditor.waitForExistence(timeout: 5))
        bodyEditor.tap()
        app.typeText("A comet knocks twice on the attic window.")

        app.buttons["save-microdraft-button"].tap()
        let skipBeat = app.buttons["Skip This Beat"]
        XCTAssertTrue(skipBeat.waitForExistence(timeout: 5))
        skipBeat.tap()

        let editButton = app.buttons.matching(identifier: "edit-draft-button").firstMatch
        XCTAssertTrue(editButton.waitForExistence(timeout: 5))
        editButton.tap()

        bodyEditor.tap()
        app.typeText(" Revised with a glowing key.")
        app.buttons["save-microdraft-button"].tap()
        XCTAssertTrue(skipBeat.waitForExistence(timeout: 5))
        skipBeat.tap()

        let deleteButton = app.buttons.matching(identifier: "delete-draft-button").firstMatch
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5))
        deleteButton.tap()

        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        XCTAssertTrue(alert.staticTexts["This removes the saved microdraft from this device."].exists)
        alert.buttons["Delete"].tap()

        XCTAssertTrue(app.alerts.firstMatch.waitForNonExistence(timeout: 5))
        XCTAssertFalse(app.buttons.matching(identifier: "delete-draft-button").firstMatch.waitForExistence(timeout: 2))
    }
}
