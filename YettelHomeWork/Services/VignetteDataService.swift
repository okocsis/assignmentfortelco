import Foundation

struct VignetteLoadResult {
    let vehicle: VehicleResponse
    let highwayInfo: HighwayInfoResponse
    let countyAdjacencyByVignetteType: [String: Set<String>]
    let countyShapesByVignetteType: [String: MapRegionShape]
}

protocol VignetteDataService {
    func loadInitialData() async throws(HighwayAPIError) -> VignetteLoadResult
}

struct DefaultVignetteDataService: VignetteDataService {
    let apiClient: HighwayAPIClient
    let mapRepository: MapRepository

    func loadInitialData() async throws(HighwayAPIError) -> VignetteLoadResult {
        let vehicle = try await apiClient.fetchVehicle()
        let highwayInfo = try await apiClient.fetchHighwayInfo()

        var countyAdjacencyByVignetteType: [String: Set<String>]
        var countyShapesByVignetteType: [String: MapRegionShape]

        do {
            countyAdjacencyByVignetteType = try mapRepository.countyAdjacencyByVignetteType(mapID: "hu.counties")
            countyShapesByVignetteType = try mapRepository.countyShapesByVignetteType(mapID: "hu.counties")
        } catch {
            countyAdjacencyByVignetteType = [:]
            countyShapesByVignetteType = [:]
        }

        return VignetteLoadResult(
            vehicle: vehicle,
            highwayInfo: highwayInfo,
            countyAdjacencyByVignetteType: countyAdjacencyByVignetteType,
            countyShapesByVignetteType: countyShapesByVignetteType
        )
    }
}
