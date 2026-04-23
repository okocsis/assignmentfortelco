import Foundation
import Observation

@MainActor
@Observable
final class VignetteViewModel {
    private(set) var vehicle: VehicleResponse?
    private(set) var highwayInfo: HighwayInfoResponse?
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var countyAdjacencyByVignetteType: [String: Set<String>] = [:]
    private(set) var countyShapesByVignetteType: [String: MapRegionShape] = [:]

    private let dataService: VignetteDataService

    init(
        apiClient: any HighwayAPIClientProtocol,
        mapRepository: MapRepository
    ) {
        self.dataService = DefaultVignetteDataService(
            apiClient: apiClient,
            mapRepository: mapRepository
        )
    }

    init(dependencies: AppDependencies) {
        self.dataService = dependencies.vignetteDataService
    }

    var nationalVignettes: [NationalVignetteOption] {
        guard let info = highwayInfo else { return [] }

        return info.payload.highwayVignettes
            .compactMap(NationalVignetteOption.init)
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var countyVignettePrice: Double {
        countyVignetteTemplate?.cost ?? 0
    }

    var countyVignettes: [CountyVignetteOption] {
        guard let info = highwayInfo, let countyTemplate = countyVignetteTemplate else { return [] }

        return info.payload.counties
            .map {
                CountyVignetteOption(
                    id: $0.id,
                    name: $0.name,
                    price: countyTemplate.cost,
                    trxFee: countyTemplate.trxFee
                )
            }
    }

    private var countyVignetteTemplate: HighwayVignette? {
        guard let info = highwayInfo else { return nil }

        return info.payload.highwayVignettes
            .first(where: { $0.vignetteType.contains(where: { $0.hasPrefix("YEAR_") }) })
    }

    var orderCategory: String {
        vehicle?.type ?? "CAR"
    }

    var countySelectionInput: CountySelectionInput {
        CountySelectionInput(
            countyVignettes: countyVignettes,
            countyVignettePrice: countyVignettePrice,
            countyAdjacencyByVignetteType: countyAdjacencyByVignetteType,
            countyShapesByVignetteType: countyShapesByVignetteType,
            orderCategory: orderCategory,
            vehiclePlate: vehicle?.plate ?? ""
        )
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let result = try await dataService.loadInitialData()
            vehicle = result.vehicle
            highwayInfo = result.highwayInfo
            countyAdjacencyByVignetteType = result.countyAdjacencyByVignetteType
            countyShapesByVignetteType = result.countyShapesByVignetteType
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func isDirectCountyNeighbor(_ lhs: String, _ rhs: String) -> Bool {
        guard !countyAdjacencyByVignetteType.isEmpty else {
            return true
        }

        return countyAdjacencyByVignetteType[lhs]?.contains(rhs) == true
            || countyAdjacencyByVignetteType[rhs]?.contains(lhs) == true
    }

    func selectedNationalVignette(type: String?) -> NationalVignetteOption? {
        guard let type else { return nil }
        return nationalVignettes.first(where: { $0.type == type })
    }

}

struct CountyVignetteOption: Identifiable {
    let id: String
    let name: String
    let price: Double
    let trxFee: Double

    var totalPrice: Double {
        price + trxFee
    }

    var priceText: String {
        let formatted = Int(price)
            .formatted(.number.grouping(.automatic).locale(.current))
        let template = String(localized: "common.price_huf_format")
        return String(format: template, locale: .current, formatted)
    }
}

struct NationalVignetteOption: Identifiable {
    let id: String
    let type: String
    let displayName: String
    let cost: Double
    let trxFee: Double
    let sum: Double
    let sortOrder: Int

    var priceText: String {
        let formatted = Int(cost)
            .formatted(.number.grouping(.automatic).locale(.current))
        let template = String(localized: "common.price_huf_format")
        return String(format: template, locale: .current, formatted)
    }

    var totalPrice: Double {
        cost + trxFee
    }

    init?(from vignette: HighwayVignette) {
        guard vignette.vignetteType.count == 1, let type = vignette.vignetteType.first else {
            return nil
        }

        let label: String
        let sortOrder: Int

        switch type {
        case "WEEK":
            label = String(localized: "national.vignette.week")
            sortOrder = 0
        case "MONTH":
            label = String(localized: "national.vignette.month")
            sortOrder = 1
        case "DAY":
            label = String(localized: "national.vignette.day")
            sortOrder = 2
        case "YEAR":
            label = String(localized: "national.vignette.year")
            sortOrder = 3
        default:
            return nil
        }

        self.id = type
        self.type = type
        self.displayName = label
        self.cost = vignette.cost
        self.trxFee = vignette.trxFee
        self.sum = vignette.sum
        self.sortOrder = sortOrder
    }
}
