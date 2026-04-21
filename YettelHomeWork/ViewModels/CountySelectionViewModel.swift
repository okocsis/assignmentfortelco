import Foundation
import Observation

struct CountySelectionInput {
    let countyVignettes: [CountyVignetteOption]
    let countyVignettePrice: Double
    let countyAdjacencyByVignetteType: [String: Set<String>]
    let countyShapesByVignetteType: [String: MapRegionShape]
    let orderCategory: String
    let vehiclePlate: String
}

@MainActor
@Observable
final class CountySelectionViewModel {
    let input: CountySelectionInput

    private(set) var selectedCountyIDs: Set<String> = []
    private(set) var connectivityWarning: String?

    init(input: CountySelectionInput) {
        self.input = input
    }

    var canProceed: Bool {
        !selectedCountyIDs.isEmpty
    }

    var selectedCounties: [CountyVignetteOption] {
        input.countyVignettes
            .filter { selectedCountyIDs.contains($0.id) }
            .sorted { $0.name < $1.name }
    }

    var totalPriceText: String {
        let totalPrice = Double(selectedCountyIDs.count) * input.countyVignettePrice
        let formatted = Int(totalPrice)
            .formatted(.number.grouping(.automatic).locale(.current))
        let template = String(localized: "common.price_huf_format")
        return String(format: template, locale: .current, formatted)
    }

    func toggleCountySelection(_ countyID: String) {
        if selectedCountyIDs.contains(countyID) {
            selectedCountyIDs.remove(countyID)
            connectivityWarning = nil
            return
        }

        let selectedBeforeInsert = selectedCountyIDs
        selectedCountyIDs.insert(countyID)

        let directlyConnected = selectedBeforeInsert.isEmpty
            || selectedBeforeInsert.contains(where: { isDirectCountyNeighbor(countyID, $0) })

        if directlyConnected {
            connectivityWarning = nil
            return
        }

        selectedCountyIDs.remove(countyID)

        let countyName = input.countyVignettes.first(where: { $0.id == countyID })?.name ?? countyID
        let warningFormat = String(localized: "county.warning.disconnected_selection")
        connectivityWarning = String(format: warningFormat, locale: .current, countyName)
    }

    private func isDirectCountyNeighbor(_ lhs: String, _ rhs: String) -> Bool {
        guard !input.countyAdjacencyByVignetteType.isEmpty else {
            return true
        }

        return input.countyAdjacencyByVignetteType[lhs]?.contains(rhs) == true
            || input.countyAdjacencyByVignetteType[rhs]?.contains(lhs) == true
    }
}
