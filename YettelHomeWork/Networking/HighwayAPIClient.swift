import Foundation

protocol HighwayAPIClientProtocol {
    func fetchVehicle() async throws(HighwayAPIError) -> VehicleResponse
    func fetchHighwayInfo() async throws(HighwayAPIError) -> HighwayInfoResponse
    func placeOrder(_ orders: [OrderItem]) async throws(HighwayAPIError) -> OrderResponse
    func send<Request: HighwayAPIRequest>(_ requestModel: Request) async throws(HighwayAPIError) -> Request.Response
}

struct HighwayAPIClient: HighwayAPIClientProtocol {
    let baseURL: URL
    let session: URLSession

    init(
        baseURL: URL,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }

    func fetchVehicle() async throws(HighwayAPIError) -> VehicleResponse {
        try await send(FetchVehicleRequest())
    }

    func fetchHighwayInfo() async throws(HighwayAPIError) -> HighwayInfoResponse {
        try await send(FetchHighwayInfoRequest())
    }

    func placeOrder(_ orders: [OrderItem]) async throws(HighwayAPIError) -> OrderResponse {
        try await send(PlaceOrderRequest(payload: OrderRequest(highwayOrders: orders)))
    }

    func send<Request: HighwayAPIRequest>(_ requestModel: Request) async throws(HighwayAPIError) -> Request.Response {
        let url = baseURL.appending(path: requestModel.path)
        var request = URLRequest(url: url)
        request.httpMethod = requestModel.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let payload = requestModel.payload {
            let body: Data
            do {
                body = try JSONEncoder().encode(payload)
            } catch {
                throw .encodingFailed(error)
            }

            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw .transport(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw .invalidResponse
        }

        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            let serverMessage = String(data: data, encoding: .utf8)
            throw .httpError(code: httpResponse.statusCode, message: serverMessage)
        }

        do {
            return try JSONDecoder().decode(Request.Response.self, from: data)
        } catch {
            throw .decodingFailed(error)
        }
    }
}



protocol HighwayAPIRequest {
    associatedtype Payload: Encodable
    associatedtype Response: Decodable

    var path: String { get }
    var method: HTTPMethod { get }
    var payload: Payload? { get }
}

struct EmptyPayload: Encodable {}

struct FetchVehicleRequest: HighwayAPIRequest {
    typealias Payload = EmptyPayload
    typealias Response = VehicleResponse

    let path = "/v1/highway/vehicle"
    let method: HTTPMethod = .get
    let payload: EmptyPayload? = nil

    static let mock = FetchVehicleRequest()
}

struct FetchHighwayInfoRequest: HighwayAPIRequest {
    typealias Payload = EmptyPayload
    typealias Response = HighwayInfoResponse

    let path = "/v1/highway/info"
    let method: HTTPMethod = .get
    let payload: EmptyPayload? = nil

    static let mock = FetchHighwayInfoRequest()
}

struct PlaceOrderRequest: HighwayAPIRequest {
    typealias Payload = OrderRequest
    typealias Response = OrderResponse

    let path = "/v1/highway/order"
    let method: HTTPMethod = .post
    let payload: OrderRequest?

    static let mock = PlaceOrderRequest(payload: .mock)
}


struct MockHighwayAPIClient: HighwayAPIClientProtocol {
    var vehicleResponse: VehicleResponse
    var highwayInfoResponse: HighwayInfoResponse
    var orderResponse: OrderResponse
    var placeOrderHandler: (([OrderItem]) -> OrderResponse)?

    init(
        vehicleResponse: VehicleResponse = .mock,
        highwayInfoResponse: HighwayInfoResponse = .mock,
        orderResponse: OrderResponse = .mockSuccess,
        placeOrderHandler: (([OrderItem]) -> OrderResponse)? = nil
    ) {
        self.vehicleResponse = vehicleResponse
        self.highwayInfoResponse = highwayInfoResponse
        self.orderResponse = orderResponse
        self.placeOrderHandler = placeOrderHandler
    }

    func fetchVehicle() async throws(HighwayAPIError) -> VehicleResponse {
        vehicleResponse
    }

    func fetchHighwayInfo() async throws(HighwayAPIError) -> HighwayInfoResponse {
        highwayInfoResponse
    }

    func placeOrder(_ orders: [OrderItem]) async throws(HighwayAPIError) -> OrderResponse {
        placeOrderHandler?(orders) ?? orderResponse
    }

    func send<Request: HighwayAPIRequest>(_ requestModel: Request) async throws(HighwayAPIError) -> Request.Response {
        if requestModel is FetchVehicleRequest, let response = vehicleResponse as? Request.Response {
            return response
        }

        if requestModel is FetchHighwayInfoRequest, let response = highwayInfoResponse as? Request.Response {
            return response
        }

        if let placeOrderRequest = requestModel as? PlaceOrderRequest {
            let orders = placeOrderRequest.payload?.highwayOrders ?? []
            let response = placeOrderHandler?(orders) ?? orderResponse
            if let typedResponse = response as? Request.Response {
                return typedResponse
            }
        }

        throw .invalidResponse
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

enum HighwayAPIError: LocalizedError {
    case invalidResponse
    case httpError(code: Int, message: String?)
    case transport(Error)
    case encodingFailed(Error)
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response."
        case let .httpError(code, message):
            if let message, !message.isEmpty {
                return "HTTP \(code): \(message)"
            }
            return "HTTP \(code)"
        case let .transport(error):
            return "Network request failed: \(error.localizedDescription)"
        case let .encodingFailed(error):
            return "Failed to encode request payload: \(error.localizedDescription)"
        case let .decodingFailed(error):
            return "Failed to decode API response: \(error.localizedDescription)"
        }
    }
}
