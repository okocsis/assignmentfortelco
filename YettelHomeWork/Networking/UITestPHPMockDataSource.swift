import Foundation

enum UITestOrderResultOverride {
    case success
    case failure
}

enum UITestPHPMockDataSource {
    static let vehicleResponse = VehicleResponse(
        requestId: 12_000_003,
        statusCode: "OK",
        internationalRegistrationCode: "H",
        type: "CAR",
        name: "Michael Scott",
        plate: "abc-123",
        country: LocalizedName(hu: "Magyarország", en: "Hungary"),
        vignetteType: "D1"
    )

    static let highwayInfoResponse = HighwayInfoResponse(
        requestId: 18_000_003,
        statusCode: "OK",
        payload: HighwayInfoPayload(
            highwayVignettes: [
                HighwayVignette(vignetteType: ["DAY"], vehicleCategory: "CAR", cost: 5150.0, trxFee: 200.0, sum: 5350.0),
                HighwayVignette(vignetteType: ["MONTH"], vehicleCategory: "CAR", cost: 10360.0, trxFee: 200.0, sum: 10560.0),
                HighwayVignette(vignetteType: ["WEEK"], vehicleCategory: "CAR", cost: 6400.0, trxFee: 200.0, sum: 6600.0),
                HighwayVignette(vignetteType: ["YEAR"], vehicleCategory: "CAR", cost: 6660.0, trxFee: 200.0, sum: 6860.0),
                HighwayVignette(
                    vignetteType: [
                        "YEAR_11", "YEAR_12", "YEAR_13", "YEAR_14", "YEAR_15", "YEAR_16", "YEAR_17", "YEAR_18", "YEAR_19", "YEAR_20",
                        "YEAR_21", "YEAR_22", "YEAR_23", "YEAR_24", "YEAR_25", "YEAR_26", "YEAR_27", "YEAR_28", "YEAR_29",
                    ],
                    vehicleCategory: "CAR",
                    cost: 6660.0,
                    trxFee: 200.0,
                    sum: 6860.0
                ),
            ],
            vehicleCategories: [
                VehicleCategory(
                    category: "CAR",
                    vignetteCategory: "D1",
                    name: LocalizedName(hu: "Személygépjármű", en: "Car")
                ),
            ],
            counties: [
                County(id: "YEAR_11", name: "Bács-Kiskun"),
                County(id: "YEAR_12", name: "Baranya"),
                County(id: "YEAR_13", name: "Békés"),
                County(id: "YEAR_14", name: "Borsod-Abaúj-Zemplén"),
                County(id: "YEAR_15", name: "Csongrád"),
                County(id: "YEAR_16", name: "Fejér"),
                County(id: "YEAR_17", name: "Győr-Moson-Sopron"),
                County(id: "YEAR_18", name: "Hajdú-Bihar"),
                County(id: "YEAR_19", name: "Heves"),
                County(id: "YEAR_20", name: "Jász-Nagykun-Szolnok"),
                County(id: "YEAR_21", name: "Komárom-Esztergom"),
                County(id: "YEAR_22", name: "Nógrád"),
                County(id: "YEAR_23", name: "Pest"),
                County(id: "YEAR_24", name: "Somogy"),
                County(id: "YEAR_25", name: "Szabolcs-Szatmár-Bereg"),
                County(id: "YEAR_26", name: "Tolna"),
                County(id: "YEAR_27", name: "Vas"),
                County(id: "YEAR_28", name: "Veszprém"),
                County(id: "YEAR_29", name: "Zala"),
            ]
        ),
        dataType: "HighwayTransaction"
    )

    static func orderResponse(for orders: [OrderItem]) -> OrderResponse {
        if orders.isEmpty {
            return OrderResponse(
                requestId: 21_000_003,
                statusCode: "ERROR",
                receivedOrders: nil,
                message: "Invalid or missing highwayOrders parameter"
            )
        }

        return OrderResponse(
            requestId: 24_000_003,
            statusCode: "OK",
            receivedOrders: orders,
            message: nil
        )
    }
}

struct UITestPHPMockHighwayAPIClient: HighwayAPIClientProtocol {
    let orderResultOverride: UITestOrderResultOverride?

    init(orderResultOverride: UITestOrderResultOverride? = nil) {
        self.orderResultOverride = orderResultOverride
    }

    func fetchVehicle() async throws(HighwayAPIError) -> VehicleResponse {
        UITestPHPMockDataSource.vehicleResponse
    }

    func fetchHighwayInfo() async throws(HighwayAPIError) -> HighwayInfoResponse {
        UITestPHPMockDataSource.highwayInfoResponse
    }

    func placeOrder(_ orders: [OrderItem]) async throws(HighwayAPIError) -> OrderResponse {
        guard let orderResultOverride else {
            return UITestPHPMockDataSource.orderResponse(for: orders)
        }

        switch orderResultOverride {
        case .success:
            return OrderResponse(
                requestId: 27_000_003,
                statusCode: "OK",
                receivedOrders: orders,
                message: nil
            )
        case .failure:
            return OrderResponse(
                requestId: 30_000_003,
                statusCode: "ERROR",
                receivedOrders: nil,
                message: "Forced UI test mock failure"
            )
        }
    }

    func send<Request: HighwayAPIRequest>(_ requestModel: Request) async throws(HighwayAPIError) -> Request.Response {
        if requestModel is FetchVehicleRequest, let response = UITestPHPMockDataSource.vehicleResponse as? Request.Response {
            return response
        }

        if requestModel is FetchHighwayInfoRequest, let response = UITestPHPMockDataSource.highwayInfoResponse as? Request.Response {
            return response
        }

        if let placeOrderRequest = requestModel as? PlaceOrderRequest {
            let orders = placeOrderRequest.payload?.highwayOrders ?? []
            let response = try await placeOrder(orders)
            if let typedResponse = response as? Request.Response {
                return typedResponse
            }
        }

        throw .invalidResponse
    }
}
