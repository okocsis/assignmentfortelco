import XCTest

enum UITestIDs {
    static let homeCountyFlowButton = "home.countyFlowButton"
    static let disconnectedWarning = "county.warning.disconnected"

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
        mockOrderResult: String = "success"
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(\(language))", "-AppleLocale", locale]

        if useMockAPI {
            app.launchArguments += ["UITEST_MOCK_API", "-mock-order-result", mockOrderResult]
        }

        if let apiBaseURL {
            app.launchArguments += ["-api-base-url", apiBaseURL]
        }

        app.launch()
        appUnderTest = app
        return app
    }
}
