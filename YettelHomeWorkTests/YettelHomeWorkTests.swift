//
//  YettelHomeWorkTests.swift
//  YettelHomeWorkTests
//
//  Created by Olivér Kocsis on 2026. 04. 17..
//

import Testing
@testable import YettelHomeWork

struct YettelHomeWorkTests {
    @Test func buildsAdjacencyFromDescriptorRegions() throws {
        let descriptor = MapDescriptor(
            schemaVersion: 1,
            countryCode: "HU",
            svgAssetName: nil,
            regions: [
                MapRegion(regionKey: "hu.alpha", associatedVignetteTypes: ["YEAR_11"], neighbors: ["hu.beta", "hu.gamma"]),
                MapRegion(regionKey: "hu.beta", associatedVignetteTypes: ["YEAR_12"], neighbors: ["hu.alpha"]),
                MapRegion(regionKey: "hu.gamma", associatedVignetteTypes: [], neighbors: ["hu.alpha"]),
            ]
        )

        let adjacency = buildAdjacencyByVignetteType(from: descriptor)

        #expect(adjacency["YEAR_11"] == Set(["YEAR_12"]))
        #expect(adjacency["YEAR_12"] == Set(["YEAR_11"]))
        #expect(adjacency["YEAR_13"] == nil)
    }

    @Test func directNeighborReturnsTrueWhenAdjacencyUnavailable() async throws {
        let result = await MainActor.run { () -> Bool in
            let viewModel = VignetteViewModel(apiClient: MockHighwayAPIClient(), mapRepository: MockFailingMapRepository())
            return viewModel.isDirectCountyNeighbor("YEAR_11", "YEAR_12")
        }
        #expect(result)
    }

    @MainActor
    @Test func uiTestMockHighwayInfoMatchesPHPFixture() async throws {
        let client = UITestPHPMockHighwayAPIClient()
        let info = try await client.fetchHighwayInfo()

        #expect(info.statusCode == "OK")
        #expect(info.dataType == "HighwayTransaction")
        #expect(info.payload.counties.count == 19)
        #expect(info.payload.counties.contains(where: { $0.id == "YEAR_25" && $0.name == "Szabolcs-Szatmár-Bereg" }))

        let dayVignette = info.payload.highwayVignettes.first(where: { $0.vignetteType == ["DAY"] && $0.vehicleCategory == "CAR" })
        #expect(dayVignette?.cost == 5150.0)
        #expect(dayVignette?.trxFee == 200.0)
        #expect(dayVignette?.sum == 5350.0)
    }

    @MainActor
    @Test func uiTestMockOrderValidationMimicsPHP() async throws {
        let client = UITestPHPMockHighwayAPIClient()

        let emptyOrderResponse = try await client.placeOrder([])
        #expect(emptyOrderResponse.statusCode == "ERROR")
        #expect(emptyOrderResponse.message == "Invalid or missing highwayOrders parameter")
        #expect(emptyOrderResponse.receivedOrders == nil)

        let validOrder = OrderItem(type: "YEAR_12", category: "CAR", cost: 6860.0)
        let successOrderResponse = try await client.placeOrder([validOrder])
        #expect(successOrderResponse.statusCode == "OK")
        #expect(successOrderResponse.receivedOrders?.count == 1)
        #expect(successOrderResponse.receivedOrders?.first?.type == "YEAR_12")
    }

    @Test func countyScenarioIncludesTransactionFeeSummaryAsLastDetailRow() {
        let scenario = PurchaseConfirmationScenario.county(
            selectedCounties: [
                CountyVignetteOption(id: "YEAR_12", name: "Baranya", price: 6860, trxFee: 200),
                CountyVignetteOption(id: "YEAR_25", name: "Szabolcs-Szatmar-Bereg", price: 6860, trxFee: 150),
            ],
            vehiclePlate: "abc-123",
            orderCategory: "CAR"
        )

        let detailRows = scenario.detailRows

        #expect(detailRows.count == 3)
        #expect(detailRows.last?.id == "transaction_fee_total")
        #expect(detailRows.last?.value == purchaseConfirmationPriceText(350))
        #expect(detailRows.last?.emphasizedTitle == false)
    }

    @Test func countyScenarioOmitsTransactionFeeSummaryWhenFeeIsZero() {
        let scenario = PurchaseConfirmationScenario.county(
            selectedCounties: [
                CountyVignetteOption(id: "YEAR_12", name: "Baranya", price: 6860, trxFee: 0),
                CountyVignetteOption(id: "YEAR_25", name: "Szabolcs-Szatmar-Bereg", price: 6860, trxFee: 0),
            ],
            vehiclePlate: "abc-123",
            orderCategory: "CAR"
        )

        #expect(scenario.detailRows.count == 2)
        #expect(scenario.detailRows.contains(where: { $0.id == "transaction_fee_total" }) == false)
    }

    @Test func purchaseConfirmationScenarioTotalsAndOrderItemsMatchSelection() {
        let national = PurchaseConfirmationScenario.national(
            vignette: NationalVignetteOption(from: HighwayVignette(vignetteType: ["MONTH"], vehicleCategory: "CAR", cost: 10360, trxFee: 200, sum: 10560))!,
            vehiclePlate: "abc-123",
            orderCategory: "CAR"
        )
        #expect(national.totalPriceText == purchaseConfirmationPriceText(10560))
        #expect(national.orderItems.count == 1)
        #expect(national.orderItems.first?.type == "MONTH")
        #expect(national.orderItems.first?.cost == 10560)

        let county = PurchaseConfirmationScenario.county(
            selectedCounties: [
                CountyVignetteOption(id: "YEAR_12", name: "Baranya", price: 6860, trxFee: 200),
                CountyVignetteOption(id: "YEAR_25", name: "Szabolcs-Szatmar-Bereg", price: 7000, trxFee: 200),
            ],
            vehiclePlate: "abc-123",
            orderCategory: "CAR"
        )
        #expect(county.totalPriceText == purchaseConfirmationPriceText(13860))
        #expect(county.orderItems.map(\.type) == ["YEAR_12", "YEAR_25"])
        #expect(county.orderItems.map(\.cost) == [6860, 7000])
    }

    @MainActor
    @Test func countySelectionViewModelTogglingUpdatesWarningAndTotal() {
        let viewModel = CountySelectionViewModel(input: .mock(
            countyVignettes: [
                CountyVignetteOption(id: "A", name: "Alpha", price: 6860, trxFee: 200),
                CountyVignetteOption(id: "B", name: "Beta", price: 6860, trxFee: 200),
                CountyVignetteOption(id: "C", name: "Gamma", price: 6860, trxFee: 200),
            ],
            countyAdjacencyByVignetteType: [
                "A": ["B"],
                "B": ["A"],
            ]
        ))

        viewModel.toggleCountySelection("A")
        #expect(viewModel.connectivityWarning == nil)
        #expect(viewModel.totalPriceText == purchaseConfirmationPriceText(6860))

        viewModel.toggleCountySelection("C")
        #expect(viewModel.connectivityWarning != nil)
        #expect(viewModel.totalPriceText == purchaseConfirmationPriceText(13720))

        viewModel.toggleCountySelection("C")
        #expect(viewModel.connectivityWarning == nil)
        #expect(viewModel.totalPriceText == purchaseConfirmationPriceText(6860))

        viewModel.toggleCountySelection("B")
        #expect(viewModel.connectivityWarning == nil)
        #expect(viewModel.totalPriceText == purchaseConfirmationPriceText(13720))
    }

    @MainActor
    @Test func countySelectionViewModelSelectedCountiesAreSortedByName() {
        let viewModel = CountySelectionViewModel(input: .mock(
            countyVignettes: [
                CountyVignetteOption(id: "Z", name: "Zulu", price: 6860, trxFee: 200),
                CountyVignetteOption(id: "A", name: "Alpha", price: 6860, trxFee: 200),
                CountyVignetteOption(id: "M", name: "Mike", price: 6860, trxFee: 200),
            ]
        ))

        viewModel.toggleCountySelection("Z")
        viewModel.toggleCountySelection("M")
        viewModel.toggleCountySelection("A")

        #expect(viewModel.selectedCounties.map(\.name) == ["Alpha", "Mike", "Zulu"])
    }

    @MainActor
    @Test func vignetteViewModelMapsNationalOrderAndPreservesCountyTemplatePricing() async {
        let response = HighwayInfoResponse(
            requestId: 1,
            statusCode: "OK",
            payload: HighwayInfoPayload(
                highwayVignettes: [
                    HighwayVignette(vignetteType: ["DAY"], vehicleCategory: "CAR", cost: 5150, trxFee: 200, sum: 5350),
                    HighwayVignette(vignetteType: ["YEAR_12"], vehicleCategory: "CAR", cost: 6660, trxFee: 240, sum: 6900),
                    HighwayVignette(vignetteType: ["YEAR"], vehicleCategory: "CAR", cost: 57260, trxFee: 200, sum: 57460),
                    HighwayVignette(vignetteType: ["WEEK"], vehicleCategory: "CAR", cost: 6400, trxFee: 200, sum: 6600),
                    HighwayVignette(vignetteType: ["MONTH"], vehicleCategory: "CAR", cost: 10360, trxFee: 200, sum: 10560),
                ],
                vehicleCategories: [],
                counties: [
                    County(id: "YEAR_12", name: "Baranya"),
                    County(id: "YEAR_25", name: "Szabolcs-Szatmar-Bereg"),
                ]
            ),
            dataType: "HighwayTransaction"
        )

        let viewModel = VignetteViewModel(
            apiClient: MockHighwayAPIClient(highwayInfoResponse: response),
            mapRepository: MockFailingMapRepository()
        )
        await viewModel.load()

        #expect(viewModel.nationalVignettes.map(\.type) == ["WEEK", "MONTH", "DAY", "YEAR"])
        #expect(viewModel.countyVignettePrice == 6900)
        #expect(viewModel.countyVignettes.map(\.price) == [6900, 6900])
        #expect(viewModel.countyVignettes.map(\.trxFee) == [240, 240])
    }

}

private extension CountySelectionInput {
    static func mock(
        countyVignettes: [CountyVignetteOption],
        countyAdjacencyByVignetteType: [String: Set<String>] = [:],
        countyVignettePrice: Double = 6860
    ) -> CountySelectionInput {
        CountySelectionInput(
            countyVignettes: countyVignettes,
            countyVignettePrice: countyVignettePrice,
            countyAdjacencyByVignetteType: countyAdjacencyByVignetteType,
            countyShapesByVignetteType: [:],
            orderCategory: "CAR",
            vehiclePlate: "abc-123"
        )
    }
}

private struct MockFailingMapRepository: MapRepository {
    func countyAdjacencyByVignetteType(mapID _: String) throws(MapRepositoryError) -> [String: Set<String>] {
        throw MapRepositoryError.assetNotFound("HUCountiesDescriptor")
    }

    func countyShapesByVignetteType(mapID _: String) throws(MapRepositoryError) -> [String: MapRegionShape] {
        throw MapRepositoryError.assetNotFound("CountyMapSVG")
    }

    func mapSVGText(mapID _: String) throws(MapRepositoryError) -> String {
        throw MapRepositoryError.assetNotFound("CountyMapSVG")
    }
}
