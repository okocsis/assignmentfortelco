import XCTest

@MainActor
final class CountySelectionUITests: UITestBaseCase {
    func testDisconnectedWarningEnglish() {
        let app = launchApp(language: "en", locale: "en_US")

        XCTContext.runActivity(named: "Open county selection screen") { _ in
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

        XCTContext.runActivity(named: "Select YEAR_12") { _ in
            let year12Row = app.buttons[UITestIDs.countyRow("YEAR_12")]
            XCTAssertTrue(
                year12Row.waitForExistence(timeout: UITestTimeouts.medium),
                "Expected county row YEAR_12 to exist on county selection screen."
            )

            if !year12Row.isHittable {
                app.swipeDown()
            }

            if year12Row.isHittable {
                year12Row.tap()
            } else {
                XCTAssertTrue(
                    year12Row.exists,
                    "Expected county row YEAR_12 to exist before coordinate fallback tap."
                )
                year12Row.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            }

            let selectedYear12Row = app.buttons
                .matching(identifier: UITestIDs.countyRow("YEAR_12"))
                .matching(NSPredicate(format: "value == %@", "selected"))
                .firstMatch
            XCTAssertTrue(
                selectedYear12Row.waitForExistence(timeout: UITestTimeouts.short),
                "Expected county row YEAR_12 to be selected after tapping."
            )
        }

        XCTContext.runActivity(named: "Select YEAR_25") { _ in
            let year25Row = app.buttons[UITestIDs.countyRow("YEAR_25")]
            XCTAssertTrue(
                year25Row.waitForExistence(timeout: UITestTimeouts.medium),
                "Expected county row YEAR_25 to exist on county selection screen."
            )

            if !year25Row.isHittable {
                for _ in 0 ..< 8 {
                    app.swipeUp()
                    if year25Row.isHittable { break }
                }
            }

            if year25Row.isHittable {
                year25Row.tap()
            } else {
                XCTAssertTrue(
                    year25Row.exists,
                    "Expected county row YEAR_25 to exist before coordinate fallback tap."
                )
                year25Row.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            }

            let selectedYear25Row = app.buttons
                .matching(identifier: UITestIDs.countyRow("YEAR_25"))
                .matching(NSPredicate(format: "value == %@", "selected"))
                .firstMatch
            XCTAssertTrue(
                selectedYear25Row.waitForExistence(timeout: UITestTimeouts.short),
                "Expected county row YEAR_25 to be selected after tapping."
            )
        }

        XCTContext.runActivity(named: "Verify disconnected warning text in English") { _ in
            let warningByID = app.staticTexts[UITestIDs.disconnectedWarning]
            let warningByText = app.staticTexts
                .containing(NSPredicate(format: "label CONTAINS[c] %@", "no direct connection"))
                .firstMatch

            let warningByIDExists = warningByID.waitForExistence(timeout: UITestTimeouts.medium)
            let warningByTextExists = warningByText.waitForExistence(timeout: UITestTimeouts.short)
            let warning = warningByIDExists ? warningByID : warningByText

            XCTAssertTrue(
                warningByIDExists || warningByTextExists,
                "Expected disconnected county warning after selecting YEAR_12 and YEAR_25. Missing both identifier '\(UITestIDs.disconnectedWarning)' and English warning text match."
            )
            XCTAssertTrue(
                warning.label.contains("has no direct connection"),
                "Expected English warning to contain 'has no direct connection', but got '\(warning.label)'."
            )
        }
    }

    func testDisconnectedWarningHungarian() {
        let app = launchApp(language: "hu", locale: "hu_HU")

        XCTContext.runActivity(named: "Open county selection screen") { _ in
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

        XCTContext.runActivity(named: "Select YEAR_12") { _ in
            let year12Row = app.buttons[UITestIDs.countyRow("YEAR_12")]
            XCTAssertTrue(
                year12Row.waitForExistence(timeout: UITestTimeouts.medium),
                "Expected county row YEAR_12 to exist on county selection screen."
            )

            if !year12Row.isHittable {
                app.swipeDown()
            }

            if year12Row.isHittable {
                year12Row.tap()
            } else {
                XCTAssertTrue(
                    year12Row.exists,
                    "Expected county row YEAR_12 to exist before coordinate fallback tap."
                )
                year12Row.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            }

            let selectedYear12Row = app.buttons
                .matching(identifier: UITestIDs.countyRow("YEAR_12"))
                .matching(NSPredicate(format: "value == %@", "selected"))
                .firstMatch
            XCTAssertTrue(
                selectedYear12Row.waitForExistence(timeout: UITestTimeouts.short),
                "Expected county row YEAR_12 to be selected after tapping."
            )
        }

        XCTContext.runActivity(named: "Select YEAR_25") { _ in
            let year25Row = app.buttons[UITestIDs.countyRow("YEAR_25")]
            XCTAssertTrue(
                year25Row.waitForExistence(timeout: UITestTimeouts.medium),
                "Expected county row YEAR_25 to exist on county selection screen."
            )

            if !year25Row.isHittable {
                for _ in 0 ..< 8 {
                    app.swipeUp()
                    if year25Row.isHittable { break }
                }
            }

            if year25Row.isHittable {
                year25Row.tap()
            } else {
                XCTAssertTrue(
                    year25Row.exists,
                    "Expected county row YEAR_25 to exist before coordinate fallback tap."
                )
                year25Row.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            }

            let selectedYear25Row = app.buttons
                .matching(identifier: UITestIDs.countyRow("YEAR_25"))
                .matching(NSPredicate(format: "value == %@", "selected"))
                .firstMatch
            XCTAssertTrue(
                selectedYear25Row.waitForExistence(timeout: UITestTimeouts.short),
                "Expected county row YEAR_25 to be selected after tapping."
            )
        }

        XCTContext.runActivity(named: "Verify disconnected warning text in Hungarian") { _ in
            let warningByID = app.staticTexts[UITestIDs.disconnectedWarning]
            let warningByText = app.staticTexts
                .containing(NSPredicate(format: "label CONTAINS[c] %@", "nem kapcsol"))
                .firstMatch

            let warningByIDExists = warningByID.waitForExistence(timeout: UITestTimeouts.medium)
            let warningByTextExists = warningByText.waitForExistence(timeout: UITestTimeouts.short)
            let warning = warningByIDExists ? warningByID : warningByText

            XCTAssertTrue(
                warningByIDExists || warningByTextExists,
                "Expected disconnected county warning after selecting YEAR_12 and YEAR_25. Missing both identifier '\(UITestIDs.disconnectedWarning)' and Hungarian warning text match."
            )

            let label = warning.label
            let hasUnaccented = label.contains("nem kapcsolodik kozvetlenul")
            let hasAccented = label.contains("nem kapcsolódik közvetlenül")
            XCTAssertTrue(
                hasUnaccented || hasAccented,
                "Expected Hungarian warning to contain either 'nem kapcsolodik kozvetlenul' or 'nem kapcsolódik közvetlenül', but got '\(label)'."
            )
        }
    }
}
