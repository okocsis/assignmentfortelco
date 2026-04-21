import SwiftUI

struct AppDependencies {
    let vignetteDataService: VignetteDataService
    let purchaseService: PurchaseService
    let mapRepository: MapRepository

    static let live = AppDependencies(
        vignetteDataService: DefaultVignetteDataService(
            apiClient: .live,
            mapRepository: AssetMapRepository()
        ),
        purchaseService: DefaultPurchaseService(apiClient: .live),
        mapRepository: AssetMapRepository()
    )
}

extension EnvironmentValues {
    @Entry var appDependencies: AppDependencies = .live
}
