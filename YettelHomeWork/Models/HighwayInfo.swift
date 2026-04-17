import Foundation

struct HighwayInfoResponse: Decodable {
    let requestId: Int?
    let statusCode: String
    let payload: HighwayInfoPayload
    let dataType: String?
}

struct HighwayInfoPayload: Decodable {
    let highwayVignettes: [HighwayVignette]
    let vehicleCategories: [VehicleCategory]
    let counties: [County]
}

struct HighwayVignette: Decodable, Identifiable {
    let vignetteType: [String]
    let vehicleCategory: String
    let cost: Double
    let trxFee: Double
    let sum: Double

    var id: String {
        "\(vehicleCategory)-\(vignetteType.joined(separator: ","))"
    }
}

struct VehicleCategory: Decodable, Identifiable {
    let category: String
    let vignetteCategory: String
    let name: LocalizedName

    var id: String { category }
}

struct County: Decodable, Identifiable {
    let id: String
    let name: String
}
