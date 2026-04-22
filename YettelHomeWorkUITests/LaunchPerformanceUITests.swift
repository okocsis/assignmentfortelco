import XCTest

@MainActor
final class LaunchPerformanceUITests: UITestBaseCase {
    func testLaunchPerformance() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "UITEST_MOCK_API",
            "-mock-order-result", "success",
        ]

        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.terminate()
            app.launch()
        }
    }
}
