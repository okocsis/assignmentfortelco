import Foundation

struct HighwayAPIClient {
    let baseURL: URL
    let session: URLSession

    init(baseURL: URL = URL(string: "http://localhost:8080")!, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func fetchVehicle() async throws -> VehicleResponse {
        try await send(path: "/v1/highway/vehicle", method: .get)
    }

    func fetchHighwayInfo() async throws -> HighwayInfoResponse {
        try await send(path: "/v1/highway/info", method: .get)
    }

    func placeOrder(_ orders: [OrderItem]) async throws -> OrderResponse {
        let request = OrderRequest(highwayOrders: orders)
        let body = try JSONEncoder().encode(request)
        return try await send(path: "/v1/highway/order", method: .post, body: body)
    }

    private func send<T: Decodable>(path: String, method: HTTPMethod, body: Data? = nil) async throws -> T {
        let url = baseURL.appending(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HighwayAPIError.invalidResponse
        }

        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            let serverMessage = String(data: data, encoding: .utf8)
            throw HighwayAPIError.httpError(code: httpResponse.statusCode, message: serverMessage)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw HighwayAPIError.decodingFailed(error)
        }
    }
}

extension HighwayAPIClient {
    nonisolated static let live = HighwayAPIClient()
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

enum HighwayAPIError: LocalizedError {
    case invalidResponse
    case httpError(code: Int, message: String?)
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
        case let .decodingFailed(error):
            return "Failed to decode API response: \(error.localizedDescription)"
        }
    }
}
