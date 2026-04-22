protocol PurchaseService {
    func submitOrder(_ items: [OrderItem]) async throws(HighwayAPIError) -> OrderResponse
}

struct DefaultPurchaseService: PurchaseService {
    let apiClient: any HighwayAPIClientProtocol

    func submitOrder(_ items: [OrderItem]) async throws(HighwayAPIError) -> OrderResponse {
        try await apiClient.placeOrder(items)
    }
}
