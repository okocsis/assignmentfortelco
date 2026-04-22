import XCTest

@MainActor
final class NavigationUITests: UITestBaseCase {
    func testCountyBackNavigatesToHomeEnglish() {
        let app = launchApp(language: "en", locale: "en_US")

        XCTContext.runActivity(named: "Open county screen from home") { _ in
            let countyFlowButton = app.buttons[UITestIDs.homeCountyFlowButton]
            XCTAssertTrue(
                countyFlowButton.waitForExistence(timeout: UITestTimeouts.long),
                "Expected home county flow button '\(UITestIDs.homeCountyFlowButton)' to exist before navigation."
            )
            XCTAssertTrue(
                countyFlowButton.isHittable,
                "Expected home county flow button to be hittable before tapping."
            )
            countyFlowButton.tap()
        }

        XCTContext.runActivity(named: "Navigate back to home") { _ in
            let backButton = app.navigationBars.buttons.firstMatch
            XCTAssertTrue(
                backButton.waitForExistence(timeout: UITestTimeouts.medium),
                "Expected a navigation back button to exist on county screen."
            )
            XCTAssertTrue(
                backButton.isHittable,
                "Expected navigation back button to be hittable before tapping."
            )
            backButton.tap()
        }

        XCTContext.runActivity(named: "Verify home screen is visible again") { _ in
            let countyFlowButton = app.buttons[UITestIDs.homeCountyFlowButton]
            XCTAssertTrue(
                countyFlowButton.waitForExistence(timeout: UITestTimeouts.medium),
                "Expected to be back on home screen with county flow button visible after tapping back."
            )
        }
    }
}
