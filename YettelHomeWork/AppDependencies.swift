import SwiftUI
import Foundation

struct AppDependencies {
    let vignetteDataService: VignetteDataService
    let purchaseService: PurchaseService
    let mapRepository: MapRepository


    static func resolved(processInfo: ProcessInfo = .processInfo) -> AppDependencies {
        let config = AppRuntimeConfig(processInfo: processInfo)

        let apiClient: any HighwayAPIClientProtocol
        if config.useMockAPI {
            apiClient = UITestPHPMockHighwayAPIClient(
                orderResultOverride: config.mockOrderResultOverride,
                responseDelayNanoseconds: config.mockResponseDelayNanoseconds
            )
        } else {
            apiClient = HighwayAPIClient(baseURL: config.baseURL)
        }

        return AppDependencies(
            vignetteDataService: DefaultVignetteDataService(
                apiClient: apiClient,
                mapRepository: AssetMapRepository()
            ),
            purchaseService: DefaultPurchaseService(apiClient: apiClient),
            mapRepository: AssetMapRepository()
        )
    }
    
    static var mock: AppDependencies {
        let mockApiClient = MockHighwayAPIClient()
        return .init(
            vignetteDataService: DefaultVignetteDataService(
                apiClient: mockApiClient,
                mapRepository: AssetMapRepository()
            ),
            purchaseService: DefaultPurchaseService(apiClient: mockApiClient),
            mapRepository: AssetMapRepository()
        )
    }
}

extension EnvironmentValues {
    @Entry var appDependencies: AppDependencies = .resolved()
}

private struct AppRuntimeConfig {
    private static let defaultBaseURL = URL(string: "http://localhost:8080")!

    let useMockAPI: Bool
    let baseURL: URL
    let mockOrderResultOverride: UITestOrderResultOverride?
    let mockResponseDelayNanoseconds: UInt64?

    init(processInfo: ProcessInfo) {
        let launchArguments = processInfo.arguments
        let environment = processInfo.environment

        useMockAPI = launchArguments.contains("UITEST_MOCK_API") || environment["UITEST_MOCK_API"] == "1"

        if let baseURLString = Self.readValue(
            from: launchArguments,
            key: "-api-base-url",
            fallback: environment["API_BASE_URL"]
        ), let parsedURL = URL(string: baseURLString) {
     
            baseURL = parsedURL
        } else {
            baseURL = Self.defaultBaseURL
        }

        if let orderResultValue = Self.readValue(
            from: launchArguments,
            key: "-mock-order-result",
            fallback: environment["UITEST_ORDER_RESULT"]
        )?.lowercased() {
            switch orderResultValue {
            case "success":
                mockOrderResultOverride = .success
            case "failure":
                mockOrderResultOverride = .failure
            default:
                mockOrderResultOverride = nil
            }
        } else {
            mockOrderResultOverride = nil
        }

        if let delayValue = Self.readValue(
            from: launchArguments,
            key: "-mock-delay-ms",
            fallback: environment["UITEST_MOCK_DELAY_MS"]
        ), let delayMS = UInt64(delayValue), delayMS > 0 {
            mockResponseDelayNanoseconds = delayMS * 1_000_000
        } else {
            mockResponseDelayNanoseconds = nil
        }
    }

    private static func readValue(from launchArguments: [String], key: String, fallback: String?) -> String? {
        if let index = launchArguments.firstIndex(of: key), index + 1 < launchArguments.count {
            return launchArguments[index + 1]
        }
        return fallback
    }
}
