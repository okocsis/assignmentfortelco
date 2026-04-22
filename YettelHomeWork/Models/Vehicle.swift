import Foundation

struct VehicleResponse: Decodable {
    let requestId: Int?
    let statusCode: String
    let internationalRegistrationCode: String
    let type: String
    let name: String
    let plate: String
    let country: LocalizedName
    let vignetteType: String
}

extension VehicleResponse {
    static let mock = VehicleResponse(
        requestId: 1,
        statusCode: "200",
        internationalRegistrationCode: "H",
        type: "CAR",
        name: "Mock Car",
        plate: "ABC-123",
        country: LocalizedName(hu: "Magyarorszag", en: "Hungary"),
        vignetteType: "D1"
    )
}
