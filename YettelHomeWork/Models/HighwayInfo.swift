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

extension HighwayInfoResponse {
    static let mock = HighwayInfoResponse(
        requestId: 1,
        statusCode: "200",
        payload: .mock,
        dataType: "mock"
    )
}

extension HighwayInfoPayload {
    static let mock = HighwayInfoPayload(
        highwayVignettes: [
            HighwayVignette(vignetteType: ["WEEK"], vehicleCategory: "CAR", cost: 5150, trxFee: 0, sum: 5150),
            HighwayVignette(vignetteType: ["MONTH"], vehicleCategory: "CAR", cost: 10360, trxFee: 0, sum: 10360),
            HighwayVignette(vignetteType: ["DAY"], vehicleCategory: "CAR", cost: 5500, trxFee: 0, sum: 5500),
            HighwayVignette(vignetteType: ["YEAR"], vehicleCategory: "CAR", cost: 57260, trxFee: 0, sum: 57260),
            HighwayVignette(vignetteType: ["YEAR_12"], vehicleCategory: "CAR", cost: 6890, trxFee: 0, sum: 6890),
        ],
        vehicleCategories: [
            VehicleCategory(category: "CAR", vignetteCategory: "D1", name: LocalizedName(hu: "Szemelyauto", en: "Car")),
        ],
        counties: [
            County(id: "YEAR_12", name: "Baranya"),
            County(id: "YEAR_25", name: "Szabolcs-Szatmar-Bereg"),
            County(id: "YEAR_23", name: "Pest"),
        ]
    )
}
