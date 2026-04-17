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
