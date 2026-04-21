//
//  YettelHomeWorkUITests.swift
//  YettelHomeWorkUITests
//
//  Created by Olivér Kocsis on 2026. 04. 17..
//

import XCTest

final class YettelHomeWorkUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        XCUIDevice.shared.orientation = .portrait

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // XCUIAutomation Documentation
        // https://developer.apple.com/documentation/xcuiautomation
    }

    @MainActor
    func testHomeScreenLocalizationEnglish() throws {
        let app = launchApp(language: "en", locale: "en_US")

        XCTAssertTrue(app.staticTexts["E-vignette"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["National vignettes"].exists)
        XCTAssertTrue(app.buttons["Purchase"].exists)
    }

    @MainActor
    func testHomeScreenLocalizationHungarian() throws {
        let app = launchApp(language: "hu", locale: "hu_HU")

        XCTAssertTrue(app.staticTexts["E-matrica"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Országos matricák"].exists)
        XCTAssertTrue(app.buttons["Vásárlás"].exists)
    }

    @MainActor
    func testCountyTopNavigationBackNavigatesToHomeEnglish() throws {
        let app = launchApp(language: "en", locale: "en_US")

        let countyFlowButton = app.buttons["home.countyFlowButton"]
        XCTAssertTrue(countyFlowButton.waitForExistence(timeout: 5))
        countyFlowButton.tap()

        let backButton = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(backButton.waitForExistence(timeout: 5))

        backButton.tap()
        XCTAssertTrue(countyFlowButton.waitForExistence(timeout: 5))
    }

    @MainActor
    func testCountyScreenLocalizationAndWarningEnglish() throws {
        let app = launchApp(language: "en", locale: "en_US")

        let countyFlowButton = app.buttons["home.countyFlowButton"]
        XCTAssertTrue(countyFlowButton.waitForExistence(timeout: 5))
        countyFlowButton.tap()

        XCTAssertTrue(waitForCountyRows(in: app))

        let warningAppeared = triggerDisconnectedCountyWarningIfPossible(in: app, expectedSubstring: "has no direct connection")
        XCTAssertTrue(warningAppeared, "Expected a disconnected county warning in English")
    }

    @MainActor
    func testCountyScreenLocalizationAndWarningHungarian() throws {
        let app = launchApp(language: "hu", locale: "hu_HU")

        let countyFlowButton = app.buttons["home.countyFlowButton"]
        XCTAssertTrue(countyFlowButton.waitForExistence(timeout: 5))
        countyFlowButton.tap()

        XCTAssertTrue(waitForCountyRows(in: app))

        let warningAppeared = triggerDisconnectedCountyWarningIfPossible(in: app, expectedSubstring: "nem kapcsolódik közvetlenül")
        XCTAssertTrue(warningAppeared, "Expected a disconnected county warning in Hungarian")
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    @MainActor
    private func launchApp(language: String, locale: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(\(language))", "-AppleLocale", locale]
        app.launch()
        return app
    }

    @MainActor
    private func triggerDisconnectedCountyWarningIfPossible(in app: XCUIApplication, expectedSubstring: String) -> Bool {
        let countyRowPredicate = NSPredicate(format: "identifier BEGINSWITH 'county.row.'")
        let countyRows = app.buttons.matching(countyRowPredicate)
        guard countyRows.count >= 2 else {
            return false
        }

        let warningPredicate = NSPredicate(format: "label CONTAINS %@", expectedSubstring)
        let warningLabel = app.staticTexts.matching(warningPredicate).firstMatch

        let maxBaselines = min(countyRows.count, 8)

        for baselineIndex in 0 ..< maxBaselines {
            let baseline = countyRows.element(boundBy: baselineIndex)
            baseline.tap()

            for candidateIndex in 0 ..< countyRows.count where candidateIndex != baselineIndex {
                let candidate = countyRows.element(boundBy: candidateIndex)
                candidate.tap()

                if warningLabel.waitForExistence(timeout: 0.8) {
                    return true
                }

                if candidate.isSelected {
                    candidate.tap()
                }
            }

            if baseline.isSelected {
                baseline.tap()
            }
        }

        return false
    }

    @MainActor
    private func waitForCountyRows(in app: XCUIApplication, timeout: TimeInterval = 5) -> Bool {
        let countyRows = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'county.row.'"))
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if countyRows.count > 0 {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }

        return countyRows.count > 0
    }

    @MainActor
    private func waitForElement(_ element: XCUIElement, in app: XCUIApplication, timeout: TimeInterval = 5, maxSwipes: Int = 4) -> Bool {
        if element.waitForExistence(timeout: timeout) {
            return true
        }

        for _ in 0 ..< maxSwipes {
            app.swipeUp()
            if element.waitForExistence(timeout: 1.0) {
                return true
            }
        }

        for _ in 0 ..< maxSwipes {
            app.swipeDown()
            if element.waitForExistence(timeout: 1.0) {
                return true
            }
        }

        return element.exists
    }
}
