import XCTest

@MainActor
final class PurchaseFlowUITests: UITestBaseCase {
    func testCountyConfirmationShowsTransactionFeeAndDoneReturnsHomeEnglish() {
        let app = launchApp(language: "en", locale: "en_US")

        XCTContext.runActivity(named: "Open county selection screen") { _ in
            let countyFlowButton = app.buttons[UITestIDs.homeCountyFlowButton]
            XCTAssertTrue(
                countyFlowButton.waitForExistence(timeout: UITestTimeouts.long),
                "Expected home county flow button '\(UITestIDs.homeCountyFlowButton)' to exist before navigation."
            )
            countyFlowButton.tap()
        }

        XCTContext.runActivity(named: "Select two counties") { _ in
            selectCounty("YEAR_12", in: app)
            selectCounty("YEAR_25", in: app)
        }

        XCTContext.runActivity(named: "Open purchase confirmation") { _ in
            let nextButton = app.buttons[UITestIDs.countyNextButton]
            XCTAssertTrue(
                nextButton.waitForExistence(timeout: UITestTimeouts.medium),
                "Expected county next button '\(UITestIDs.countyNextButton)' to exist after selecting counties."
            )
            XCTAssertTrue(nextButton.isHittable, "Expected county next button to be hittable before tapping.")
            nextButton.tap()

            let confirmationPrimaryButton = app.buttons[UITestIDs.confirmationPrimaryButton]
            XCTAssertTrue(
                confirmationPrimaryButton.waitForExistence(timeout: UITestTimeouts.medium),
                "Expected confirmation primary button '\(UITestIDs.confirmationPrimaryButton)' on purchase confirmation screen."
            )
        }

        XCTContext.runActivity(named: "Verify transaction fee row exists") { _ in
            let transactionFeeRow = app.otherElements[UITestIDs.confirmationTransactionFeeRow]
            XCTAssertTrue(
                transactionFeeRow.waitForExistence(timeout: UITestTimeouts.medium),
                "Expected county purchase confirmation to include transaction fee row '\(UITestIDs.confirmationTransactionFeeRow)'."
            )
        }

        XCTContext.runActivity(named: "Submit and return home from result") { _ in
            let confirmationPrimaryButton = app.buttons[UITestIDs.confirmationPrimaryButton]
            confirmationPrimaryButton.tap()

            let doneButton = app.buttons[UITestIDs.resultDoneButton]
            XCTAssertTrue(
                doneButton.waitForExistence(timeout: UITestTimeouts.long),
                "Expected result done button '\(UITestIDs.resultDoneButton)' after successful submission."
            )
            doneButton.tap()

            let countyFlowButton = app.buttons[UITestIDs.homeCountyFlowButton]
            XCTAssertTrue(
                countyFlowButton.waitForExistence(timeout: UITestTimeouts.long),
                "Expected to be back on home screen after tapping Done on result screen."
            )
        }
    }

    private func selectCounty(_ countyID: String, in app: XCUIApplication) {
        let row = app.buttons[UITestIDs.countyRow(countyID)]
        XCTAssertTrue(
            row.waitForExistence(timeout: UITestTimeouts.medium),
            "Expected county row '\(countyID)' to exist on county selection screen."
        )

        if !row.isHittable {
            for _ in 0 ..< 8 {
                app.swipeUp()
                if row.isHittable { break }
            }
        }

        if row.isHittable {
            row.tap()
        } else {
            XCTAssertTrue(row.exists, "Expected county row '\(countyID)' to exist before fallback tap.")
            row.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }

        let selectedRow = app.buttons
            .matching(identifier: UITestIDs.countyRow(countyID))
            .matching(NSPredicate(format: "value == %@", "selected"))
            .firstMatch
        XCTAssertTrue(
            selectedRow.waitForExistence(timeout: UITestTimeouts.short),
            "Expected county row '\(countyID)' to be selected after tapping."
        )
    }
}
