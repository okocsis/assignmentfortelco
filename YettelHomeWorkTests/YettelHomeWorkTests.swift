//
//  YettelHomeWorkTests.swift
//  YettelHomeWorkTests
//
//  Created by Olivér Kocsis on 2026. 04. 17..
//

import Testing
@testable import YettelHomeWork

struct YettelHomeWorkTests {
    @Test func buildsAdjacencyFromDescriptorRegions() throws {
        let descriptor = MapDescriptor(
            schemaVersion: 1,
            countryCode: "HU",
            svgAssetName: nil,
            regions: [
                MapRegion(regionKey: "hu.alpha", associatedVignetteTypes: ["YEAR_11"], neighbors: ["hu.beta", "hu.gamma"]),
                MapRegion(regionKey: "hu.beta", associatedVignetteTypes: ["YEAR_12"], neighbors: ["hu.alpha"]),
                MapRegion(regionKey: "hu.gamma", associatedVignetteTypes: [], neighbors: ["hu.alpha"]),
            ]
        )

        let adjacency = buildAdjacencyByVignetteType(from: descriptor)

        #expect(adjacency["YEAR_11"] == Set(["YEAR_12"]))
        #expect(adjacency["YEAR_12"] == Set(["YEAR_11"]))
        #expect(adjacency["YEAR_13"] == nil)
    }

    @Test func directNeighborReturnsTrueWhenAdjacencyUnavailable() async throws {
        let result = await MainActor.run { () -> Bool in
            let viewModel = VignetteViewModel(apiClient: MockHighwayAPIClient(), mapRepository: MockFailingMapRepository())
            return viewModel.isDirectCountyNeighbor("YEAR_11", "YEAR_12")
        }
        #expect(result)
    }

    @MainActor
    @Test func uiTestMockHighwayInfoMatchesPHPFixture() async throws {
        let client = UITestPHPMockHighwayAPIClient()
        let info = try await client.fetchHighwayInfo()

        #expect(info.statusCode == "OK")
        #expect(info.dataType == "HighwayTransaction")
        #expect(info.payload.counties.count == 19)
        #expect(info.payload.counties.contains(where: { $0.id == "YEAR_25" && $0.name == "Szabolcs-Szatmár-Bereg" }))

        let dayVignette = info.payload.highwayVignettes.first(where: { $0.vignetteType == ["DAY"] && $0.vehicleCategory == "CAR" })
        #expect(dayVignette?.cost == 5150.0)
        #expect(dayVignette?.trxFee == 200.0)
        #expect(dayVignette?.sum == 5350.0)
    }

    @MainActor
    @Test func uiTestMockOrderValidationMimicsPHP() async throws {
        let client = UITestPHPMockHighwayAPIClient()

        let emptyOrderResponse = try await client.placeOrder([])
        #expect(emptyOrderResponse.statusCode == "ERROR")
        #expect(emptyOrderResponse.message == "Invalid or missing highwayOrders parameter")
        #expect(emptyOrderResponse.receivedOrders == nil)

        let validOrder = OrderItem(type: "YEAR_12", category: "CAR", cost: 6860.0)
        let successOrderResponse = try await client.placeOrder([validOrder])
        #expect(successOrderResponse.statusCode == "OK")
        #expect(successOrderResponse.receivedOrders?.count == 1)
        #expect(successOrderResponse.receivedOrders?.first?.type == "YEAR_12")
    }

}

private struct MockFailingMapRepository: MapRepository {
    func countyAdjacencyByVignetteType(mapID _: String) throws(MapRepositoryError) -> [String: Set<String>] {
        throw MapRepositoryError.assetNotFound("HUCountiesDescriptor")
    }

    func countyShapesByVignetteType(mapID _: String) throws(MapRepositoryError) -> [String: MapRegionShape] {
        throw MapRepositoryError.assetNotFound("CountyMapSVG")
    }

    func mapSVGText(mapID _: String) throws(MapRepositoryError) -> String {
        throw MapRepositoryError.assetNotFound("CountyMapSVG")
    }
}
