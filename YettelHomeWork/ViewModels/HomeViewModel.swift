import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    private(set) var vehicle: VehicleResponse?
    private(set) var highwayInfo: HighwayInfoResponse?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let apiClient: HighwayAPIClient

    init(apiClient: HighwayAPIClient = .live) {
        self.apiClient = apiClient
    }

    var nationalVignettes: [NationalVignetteOption] {
        guard let info = highwayInfo else { return [] }

        return info.payload.highwayVignettes
            .compactMap(NationalVignetteOption.init)
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var countyVignettePrice: Double {
        guard let info = highwayInfo else { return 0 }

        return info.payload.highwayVignettes
            .first(where: { $0.vignetteType.contains(where: { $0.hasPrefix("YEAR_") }) })?
            .sum ?? 0
    }

    var countyVignettes: [CountyVignetteOption] {
        guard let info = highwayInfo else { return [] }

        return info.payload.counties
            .map { CountyVignetteOption(id: $0.id, name: $0.name, price: countyVignettePrice) }
            .sorted { $0.name < $1.name }
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            async let vehicleRequest = apiClient.fetchVehicle()
            async let infoRequest = apiClient.fetchHighwayInfo()

            vehicle = try await vehicleRequest
            highwayInfo = try await infoRequest
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct CountyVignetteOption: Identifiable {
    let id: String
    let name: String
    let price: Double

    var priceText: String {
        let formatted = Int(price)
            .formatted(.number.grouping(.automatic).locale(Locale(identifier: "hu_HU")))
        return "\(formatted) Ft"
    }
}

struct NationalVignetteOption: Identifiable {
    let id: String
    let type: String
    let displayName: String
    let sum: Double
    let sortOrder: Int

    var priceText: String {
        let formatted = Int(sum)
            .formatted(.number.grouping(.automatic).locale(Locale(identifier: "hu_HU")))
        return "\(formatted) Ft"
    }

    init?(from vignette: HighwayVignette) {
        guard vignette.vignetteType.count == 1, let type = vignette.vignetteType.first else {
            return nil
        }

        let label: String
        let sortOrder: Int

        switch type {
        case "WEEK":
            label = "D1 - heti (10 napos)"
            sortOrder = 0
        case "MONTH":
            label = "D1 - havi"
            sortOrder = 1
        case "DAY":
            label = "D1 - napi (1 napos)"
            sortOrder = 2
        case "YEAR":
            label = "D1 - eves"
            sortOrder = 3
        default:
            return nil
        }

        self.id = type
        self.type = type
        self.displayName = label
        self.sum = vignette.sum
        self.sortOrder = sortOrder
    }
}
