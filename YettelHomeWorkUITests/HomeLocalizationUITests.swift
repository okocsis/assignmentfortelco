import XCTest

@MainActor
final class HomeLocalizationUITests: UITestBaseCase {
    func testHomeLocalizationEnglish() {
        let app = launchApp(language: "en", locale: "en_US")

        XCTContext.runActivity(named: "Verify English home title") { _ in
            let title = app.staticTexts["E-vignette"]
            XCTAssertTrue(
                title.waitForExistence(timeout: UITestTimeouts.medium),
                "Expected English home title 'E-vignette' to exist."
            )
        }

        XCTContext.runActivity(named: "Verify English national section label") { _ in
            let nationalLabel = app.staticTexts["National vignettes"]
            XCTAssertTrue(
                nationalLabel.waitForExistence(timeout: UITestTimeouts.medium),
                "Expected English national section label 'National vignettes' to exist."
            )
        }

        XCTContext.runActivity(named: "Verify English purchase button") { _ in
            let purchaseButton = app.buttons["Purchase"]
            XCTAssertTrue(
                purchaseButton.waitForExistence(timeout: UITestTimeouts.medium),
                "Expected English purchase button 'Purchase' to exist."
            )
        }
    }

    func testHomeLocalizationHungarian() {
        let app = launchApp(language: "hu", locale: "hu_HU")

        XCTContext.runActivity(named: "Verify Hungarian home title") { _ in
            let title = app.staticTexts["E-matrica"]
            XCTAssertTrue(
                title.waitForExistence(timeout: UITestTimeouts.medium),
                "Expected Hungarian home title 'E-matrica' to exist."
            )
        }

        XCTContext.runActivity(named: "Verify Hungarian national section label") { _ in
            let unaccented = app.staticTexts["Orszagos matricak"]
            let accented = app.staticTexts["Országos matricák"]
            let found = unaccented.waitForExistence(timeout: UITestTimeouts.short)
                || accented.waitForExistence(timeout: UITestTimeouts.short)
            XCTAssertTrue(
                found,
                "Expected Hungarian national section label to be either 'Orszagos matricak' or 'Országos matricák'."
            )
        }

        XCTContext.runActivity(named: "Verify Hungarian purchase button") { _ in
            let unaccented = app.buttons["Vasarlas"]
            let accented = app.buttons["Vásárlás"]
            let found = unaccented.waitForExistence(timeout: UITestTimeouts.short)
                || accented.waitForExistence(timeout: UITestTimeouts.short)
            XCTAssertTrue(
                found,
                "Expected Hungarian purchase button to be either 'Vasarlas' or 'Vásárlás'."
            )
        }
    }
}
