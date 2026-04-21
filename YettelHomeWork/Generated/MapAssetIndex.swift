import Foundation

struct MapAssetDefinition: Sendable {
    let mapID: String
    let countryCode: String
    let displayName: String
    let svgDatasetName: String
    let svgFileName: String
    let descriptorDatasetName: String
    let descriptorFileName: String
}

enum MapAssetIndex {
    static let all: [MapAssetDefinition] = [
        MapAssetDefinition(mapID: "hu.counties", countryCode: "HU", displayName: "Hungary Counties", svgDatasetName: "CountyMapSVG", svgFileName: "countyMap.svg", descriptorDatasetName: "HUCountiesDescriptor", descriptorFileName: "hu.counties.v1.json"),
    ]
}
