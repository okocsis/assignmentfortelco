import XCTest

enum UITestIDs {
    static let homeCountyFlowButton = "home.countyFlowButton"
    static let homeNationalPurchaseButton = "home.nationalPurchaseButton"
    static let homeNationalWeekOption = "home.nationalOption.WEEK"
    static let homeNationalMonthOption = "home.nationalOption.MONTH"
    static let countyNextButton = "county.nextButton"
    static let countyTotalValue = "county.totalValue"
    static let disconnectedWarning = "county.warning.disconnected"
    static let confirmationPrimaryButton = "confirmation.primaryButton"
    static let confirmationCancelButton = "confirmation.cancelButton"
    static let confirmationTransactionFeeRow = "confirmation.row.transaction_fee_total"
    static let confirmationTotalValue = "confirmation.totalValue"
    static let resultDoneButton = "result.doneButton"
    static let resultRetryButton = "result.retryButton"
    static let resultFailureMessage = "result.failureMessage"

    static func countyRow(_ countyID: String) -> String {
        "county.row.\(countyID)"
    }
}

enum UITestTimeouts {
    static let short: TimeInterval = 1.5
    static let medium: TimeInterval = 8.0
    static let long: TimeInterval = 20.0
}

@MainActor
class UITestBaseCase: XCTestCase {
    var appUnderTest: XCUIApplication?

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    override func tearDownWithError() throws {
        if let failureCount = testRun?.failureCount, failureCount > 0 {
            let screenshot = XCUIScreen.main.screenshot()
            let screenshotAttachment = XCTAttachment(screenshot: screenshot)
            screenshotAttachment.name = "Failure Screenshot - \(name)"
            screenshotAttachment.lifetime = .keepAlways
            add(screenshotAttachment)

            if let appUnderTest {
                let debugAttachment = XCTAttachment(string: appUnderTest.debugDescription)
                debugAttachment.name = "UI Hierarchy - \(name)"
                debugAttachment.lifetime = .keepAlways
                add(debugAttachment)
            }
        }

        appUnderTest = nil
        try super.tearDownWithError()
    }

    func launchApp(
        language: String,
        locale: String,
        useMockAPI: Bool = true,
        apiBaseURL: String? = nil,
        mockOrderResult: String = "success",
        mockDelayMS: Int? = nil
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(\(language))", "-AppleLocale", locale]

        if useMockAPI {
            app.launchArguments += ["UITEST_MOCK_API", "-mock-order-result", mockOrderResult]
        }

        if let apiBaseURL {
            app.launchArguments += ["-api-base-url", apiBaseURL]
        }

        if let mockDelayMS {
            app.launchArguments += ["-mock-delay-ms", String(mockDelayMS)]
        }

        app.launch()
        appUnderTest = app
        return app
    }

    func openCountyFlow(in app: XCUIApplication) {
        let countyFlowButton = app.buttons[UITestIDs.homeCountyFlowButton]
        XCTAssertTrue(
            countyFlowButton.waitForExistence(timeout: UITestTimeouts.long),
            "Expected county flow button '\(UITestIDs.homeCountyFlowButton)' on home screen."
        )
        XCTAssertTrue(countyFlowButton.isHittable, "Expected county flow button to be hittable before tapping.")
        countyFlowButton.tap()
    }

    func selectCounty(_ countyID: String, in app: XCUIApplication) {
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
