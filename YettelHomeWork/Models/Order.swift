import Foundation

struct OrderRequest: Encodable {
    let highwayOrders: [OrderItem]
}

extension OrderRequest {
    static let mock = OrderRequest(highwayOrders: [.mockCounty])
}

struct OrderItem: Codable, Identifiable {
    let type: String
    let category: String
    let cost: Double

    var id: String { "\(type)-\(category)-\(cost)" }
}

extension OrderItem {
    static let mockCounty = OrderItem(type: "YEAR_12", category: "CAR", cost: 6890)
}

struct OrderResponse: Decodable {
    let requestId: Int?
    let statusCode: String
    let receivedOrders: [OrderItem]?
    let message: String?
}

extension OrderResponse {
    static let mockSuccess = OrderResponse(
        requestId: 1,
        statusCode: "200",
        receivedOrders: [.mockCounty],
        message: "Order created"
    )

    static let mockFailure = OrderResponse(
        requestId: 2,
        statusCode: "500",
        receivedOrders: nil,
        message: "Order failed"
    )
}
