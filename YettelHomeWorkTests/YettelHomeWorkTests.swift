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
            let viewModel = VignetteViewModel(apiClient: .live, mapRepository: MockFailingMapRepository())
            return viewModel.isDirectCountyNeighbor("YEAR_11", "YEAR_12")
        }
        #expect(result)
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
