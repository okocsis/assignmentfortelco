import Foundation

struct OrderRequest: Encodable {
    let highwayOrders: [OrderItem]
}

struct OrderItem: Codable, Identifiable {
    let type: String
    let category: String
    let cost: Double

    var id: String { "\(type)-\(category)-\(cost)" }
}

struct OrderResponse: Decodable {
    let requestId: Int?
    let statusCode: String
    let receivedOrders: [OrderItem]?
    let message: String?
}
