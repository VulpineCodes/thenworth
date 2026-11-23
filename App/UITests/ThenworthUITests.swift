import XCTest

// MARK: - Thenworth UI tests (XCUITest)
//
// Key flows only: Home to a scenario, scrub the timeline, save a future.
// These files live under App/UITests/ and belong to a UI Testing target
// in Xcode (see App/README.md). XCUITest is NOT available on Linux, so
// these run on the Mac only and have never been run.
//
// The tests find controls by the accessibility identifiers set in the
// views:
// - Home scenario cards:        "scenario-card-oneTime", "scenario-card-recurring",
//                               "scenario-card-goal", "scenario-card-retirement"
// - New-scenario buttons:       "new-scenario-oneTime" (etc.)
// - Timeline scrubber:          "timeline-scrubber" (a Slider)
// - Year steppers:              "year-stepper-minus", "year-stepper-plus"
// - Dollars toggle:             "dollars-toggle"
// - Scenario title field:       "scenario-title-field"
// - Save button:                "save-scenario-button"
// - Compare toggle:             "compare-toggle-button"
// - Learn topics:               "learn-topic-compounding" (etc.)
// - Tabs:                       "Home", "My Futures", "Learn Why"

final class ThenworthUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    /// Home shows the four scenario cards, and tapping one opens its
    /// detail with a Save button.
    func testHomeToScenario() throws {
        let card = app.buttons["scenario-card-oneTime"]
        XCTAssertTrue(card.waitForExistence(timeout: 5), "One-purchase card missing on Home")
        card.tap()

        let saveButton = app.buttons["save-scenario-button"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5), "Save button missing in scenario detail")

        let scrubber = app.sliders["timeline-scrubber"]
        XCTAssertTrue(scrubber.waitForExistence(timeout: 5), "Timeline scrubber missing in the Future Lens")
    }

    /// Scrubbing the timeline updates the year shown in the Future Lens.
    func testScrubTimeline() throws {
        app.buttons["scenario-card-oneTime"].tap()

        let scrubber = app.sliders["timeline-scrubber"]
        XCTAssertTrue(scrubber.waitForExistence(timeout: 5))

        let yearLabel = app.staticTexts["lens-year-label"]
        XCTAssertTrue(yearLabel.waitForExistence(timeout: 5))
        let before = yearLabel.label

        scrubber.adjust(toNormalizedSliderPosition: 0.25)
        let after = yearLabel.label
        XCTAssertNotEqual(before, after, "Scrubbing the timeline should change the year shown")

        // The steppers move one year at a time.
        let plus = app.buttons["year-stepper-plus"]
        XCTAssertTrue(plus.exists)
        plus.tap()
    }

    /// Saving a future makes it appear in My Futures.
    func testSaveFuture() throws {
        app.buttons["scenario-card-recurring"].tap()

        let saveButton = app.buttons["save-scenario-button"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.tap()

        // The save confirmation alert offers Done.
        let doneButton = app.alerts.buttons["Done"]
        if doneButton.waitForExistence(timeout: 3) {
            doneButton.tap()
        }

        app.tabBars.buttons["My Futures"].tap()
        // The list shows at least one saved scenario cell.
        let cells = app.cells
        XCTAssertTrue(cells.firstMatch.waitForExistence(timeout: 5), "No saved scenarios in My Futures after saving")
    }

    /// The dollars toggle switches between today's and future dollars.
    func testDollarsToggle() throws {
        app.buttons["scenario-card-oneTime"].tap()

        let toggle = app.segmentedControls["dollars-toggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        toggle.buttons["Future $"].tap()
        toggle.buttons["Today's $"].tap()
    }

    /// Learn Why lists the four topics and opens one.
    func testLearnWhy() throws {
        app.tabBars.buttons["Learn Why"].tap()

        let topic = app.buttons["learn-topic-compounding"]
        XCTAssertTrue(topic.waitForExistence(timeout: 5), "Compounding topic missing in Learn Why")
        topic.tap()
        XCTAssertTrue(app.staticTexts["Compounding"].waitForExistence(timeout: 5))
    }
}
