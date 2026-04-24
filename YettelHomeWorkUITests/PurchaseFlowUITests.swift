import XCTest

@MainActor
final class PurchaseFlowUITests: UITestBaseCase {
    func testNationalPurchaseSuccessShowsFeeAndDoneReturnsHomeEnglish() {
        let app = launchApp(language: "en", locale: "en_US", mockOrderResult: "success")

        XCTContext.runActivity(named: "Open national confirmation from home") { _ in
            let weekOption = app.buttons[UITestIDs.homeNationalWeekOption]
            XCTAssertTrue(
                weekOption.waitForExistence(timeout: UITestTimeouts.long),
                "Expected national WEEK option '\(UITestIDs.homeNationalWeekOption)' to exist on home screen."
            )
            XCTAssertEqual(weekOption.value as? String, "6,400 HUF")

            let purchaseButton = app.buttons[UITestIDs.homeNationalPurchaseButton]
            XCTAssertTrue(
                purchaseButton.waitForExistence(timeout: UITestTimeouts.medium),
                "Expected national purchase button '\(UITestIDs.homeNationalPurchaseButton)' on home screen."
            )
            purchaseButton.tap()
        }

        XCTContext.runActivity(named: "Verify fee row and total on confirmation") { _ in
            let feeRow = app.staticTexts[UITestIDs.confirmationTransactionFeeRow]
            XCTAssertTrue(
                feeRow.waitForExistence(timeout: UITestTimeouts.medium),
                "Expected transaction fee row on national purchase confirmation screen."
            )
            XCTAssertEqual(feeRow.value as? String, "200 HUF")

            let totalValue = app.staticTexts[UITestIDs.confirmationTotalValue]
            XCTAssertTrue(totalValue.waitForExistence(timeout: UITestTimeouts.medium))
            XCTAssertEqual(totalValue.label, "6,600 HUF")
        }

        XCTContext.runActivity(named: "Submit and return to home") { _ in
            let confirmationPrimaryButton = app.buttons[UITestIDs.confirmationPrimaryButton]
            XCTAssertTrue(confirmationPrimaryButton.waitForExistence(timeout: UITestTimeouts.medium))
            confirmationPrimaryButton.tap()

            let doneButton = app.buttons[UITestIDs.resultDoneButton]
            XCTAssertTrue(doneButton.waitForExistence(timeout: UITestTimeouts.long))
            doneButton.tap()

            let homeCountyButton = app.buttons[UITestIDs.homeCountyFlowButton]
            XCTAssertTrue(homeCountyButton.waitForExistence(timeout: UITestTimeouts.long))
        }
    }

    func testCountyConfirmationShowsTransactionFeeAndDoneReturnsHomeEnglish() {
        let app = launchApp(language: "en", locale: "en_US", mockOrderResult: "success")

        XCTContext.runActivity(named: "Open county selection screen") { _ in
            openCountyFlow(in: app)
        }

        XCTContext.runActivity(named: "Select two counties") { _ in
            selectCounty("YEAR_12", in: app)
            selectCounty("YEAR_25", in: app)

            let countyTotalValue = app.staticTexts[UITestIDs.countyTotalValue]
            XCTAssertTrue(countyTotalValue.waitForExistence(timeout: UITestTimeouts.medium))
            XCTAssertEqual(countyTotalValue.label, "13,320 HUF")
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

            let totalValue = app.staticTexts[UITestIDs.confirmationTotalValue]
            XCTAssertTrue(totalValue.waitForExistence(timeout: UITestTimeouts.medium))
            XCTAssertEqual(totalValue.label, "13,720 HUF")
        }

        XCTContext.runActivity(named: "Verify transaction fee row exists") { _ in
            let transactionFeeRow = app.staticTexts[UITestIDs.confirmationTransactionFeeRow]
            XCTAssertTrue(
                transactionFeeRow.waitForExistence(timeout: UITestTimeouts.medium),
                "Expected county purchase confirmation to include transaction fee row '\(UITestIDs.confirmationTransactionFeeRow)'."
            )
            XCTAssertEqual(transactionFeeRow.value as? String, "400 HUF")
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

    func testCountyPurchaseFailureShowsRetryPathAndReturnsToConfirmation() {
        let app = launchApp(language: "en", locale: "en_US", mockOrderResult: "failure")

        openCountyFlow(in: app)
        selectCounty("YEAR_12", in: app)
        let nextButton = app.buttons[UITestIDs.countyNextButton]
        XCTAssertTrue(nextButton.waitForExistence(timeout: UITestTimeouts.medium))
        nextButton.tap()

        let confirmationPrimaryButton = app.buttons[UITestIDs.confirmationPrimaryButton]
        XCTAssertTrue(confirmationPrimaryButton.waitForExistence(timeout: UITestTimeouts.medium))
        confirmationPrimaryButton.tap()

        let retryButton = app.buttons[UITestIDs.resultRetryButton]
        XCTAssertTrue(
            retryButton.waitForExistence(timeout: UITestTimeouts.long),
            "Expected retry button on failure result screen in county flow."
        )
        let failureMessage = app.staticTexts[UITestIDs.resultFailureMessage]
        XCTAssertTrue(failureMessage.waitForExistence(timeout: UITestTimeouts.medium))

        retryButton.tap()
        XCTAssertTrue(
            app.buttons[UITestIDs.confirmationPrimaryButton].waitForExistence(timeout: UITestTimeouts.medium),
            "Expected retry to dismiss failure result back to purchase confirmation."
        )
    }

    func testNationalPurchaseFailureShowsRetryPathAndReturnsToConfirmation() {
        let app = launchApp(language: "en", locale: "en_US", mockOrderResult: "failure")

        let purchaseButton = app.buttons[UITestIDs.homeNationalPurchaseButton]
        XCTAssertTrue(purchaseButton.waitForExistence(timeout: UITestTimeouts.long))
        purchaseButton.tap()

        let confirmationPrimaryButton = app.buttons[UITestIDs.confirmationPrimaryButton]
        XCTAssertTrue(confirmationPrimaryButton.waitForExistence(timeout: UITestTimeouts.medium))
        confirmationPrimaryButton.tap()

        let retryButton = app.buttons[UITestIDs.resultRetryButton]
        XCTAssertTrue(
            retryButton.waitForExistence(timeout: UITestTimeouts.long),
            "Expected retry button on failure result screen in national flow."
        )
        retryButton.tap()

        XCTAssertTrue(app.buttons[UITestIDs.confirmationPrimaryButton].waitForExistence(timeout: UITestTimeouts.medium))
    }

    func testConfirmationCancelNavigatesBackOneLevelToCountySelection() {
        let app = launchApp(language: "en", locale: "en_US", mockOrderResult: "success")

        openCountyFlow(in: app)
        selectCounty("YEAR_12", in: app)

        let nextButton = app.buttons[UITestIDs.countyNextButton]
        XCTAssertTrue(nextButton.waitForExistence(timeout: UITestTimeouts.medium))
        nextButton.tap()

        let cancelButton = app.buttons[UITestIDs.confirmationCancelButton]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: UITestTimeouts.medium))
        cancelButton.tap()

        XCTAssertTrue(
            app.buttons[UITestIDs.countyNextButton].waitForExistence(timeout: UITestTimeouts.medium),
            "Expected cancel on confirmation to navigate back one level to county selection."
        )
    }

    func testConfirmationSubmitDisablesButtonWhileWaitingForDelayedMockResponse() {
        let app = launchApp(language: "en", locale: "en_US", mockOrderResult: "success", mockDelayMS: 1200)

        let purchaseButton = app.buttons[UITestIDs.homeNationalPurchaseButton]
        XCTAssertTrue(purchaseButton.waitForExistence(timeout: UITestTimeouts.long))
        purchaseButton.tap()

        let confirmationPrimaryButton = app.buttons[UITestIDs.confirmationPrimaryButton]
        XCTAssertTrue(confirmationPrimaryButton.waitForExistence(timeout: UITestTimeouts.medium))
        XCTAssertTrue(confirmationPrimaryButton.isEnabled)
        confirmationPrimaryButton.tap()

        XCTAssertFalse(
            confirmationPrimaryButton.isEnabled,
            "Expected confirmation primary button to be disabled while submission is in progress."
        )

        XCTAssertTrue(
            app.buttons[UITestIDs.resultDoneButton].waitForExistence(timeout: UITestTimeouts.long),
            "Expected submission to complete and show result done button after delayed response."
        )
    }
}
