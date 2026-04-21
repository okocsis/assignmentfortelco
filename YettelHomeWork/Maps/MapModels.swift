import Foundation
import CoreGraphics

struct MapDescriptor: Decodable {
    let schemaVersion: Int
    let countryCode: String
    let svgAssetName: String?
    let regions: [MapRegion]
}

struct MapRegion: Decodable {
    let regionKey: String
    let associatedVignetteTypes: [String]
    let neighbors: [String]
}

struct MapPolyline: Sendable {
    let points: [CGPoint]
    let isClosed: Bool
}

struct MapRegionShape: Sendable {
    let polylines: [MapPolyline]
}
