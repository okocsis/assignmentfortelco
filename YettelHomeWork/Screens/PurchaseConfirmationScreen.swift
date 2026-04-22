import SwiftUI

enum PurchaseConfirmationScenario {
    case national(vignette: NationalVignetteOption, vehiclePlate: String, orderCategory: String)
    case county(selectedCounties: [CountyVignetteOption], vehiclePlate: String, orderCategory: String)

    var vehiclePlate: String {
        switch self {
        case let .national(_, vehiclePlate, _):
            vehiclePlate
        case let .county(_, vehiclePlate, _):
            vehiclePlate
        }
    }

    var productSummary: String {
        switch self {
        case let .national(vignette, _, _):
            vignette.displayName
        case let .county(selectedCounties, _, _):
            String(format: String(localized: "confirmation.county_count"), locale: .current, selectedCounties.count)
        }
    }

    var detailRows: [PurchaseConfirmationDetailRow] {
        switch self {
        case .national:
            []
        case let .county(selectedCounties, _, _):
            selectedCounties.map {
                PurchaseConfirmationDetailRow(id: $0.id, title: $0.name, value: $0.priceText, emphasizedTitle: true)
            }
        }
    }

    var totalLabel: LocalizedStringKey {
        switch self {
        case .national:
            "confirmation.total"
        case .county:
            "county.total_price.label"
        }
    }

    var totalPriceText: String {
        switch self {
        case let .national(vignette, _, _):
            return vignette.priceText
        case let .county(selectedCounties, _, _):
            let total = selectedCounties.reduce(0) { $0 + $1.price }
            return purchaseConfirmationPriceText(total)
        }
    }

    var orderItems: [OrderItem] {
        switch self {
        case let .national(vignette, _, orderCategory):
            [OrderItem(type: vignette.type, category: orderCategory, cost: vignette.sum)]
        case let .county(selectedCounties, _, orderCategory):
            selectedCounties.map {
                OrderItem(type: $0.id, category: orderCategory, cost: $0.price)
            }
        }
    }

    var isSubmittable: Bool {
        !orderItems.isEmpty
    }
}

struct PurchaseConfirmationScreen: View {
    let scenario: PurchaseConfirmationScenario
    @Environment(\.dismiss) private var dismiss
    @State private var submissionViewModel: PurchaseSubmissionViewModel

    private enum Metrics {
        static let totalSectionSpacing: CGFloat = 6
    }

    init(
        scenario: PurchaseConfirmationScenario,
        purchaseService: PurchaseService
    ) {
        self.scenario = scenario
        _submissionViewModel = State(initialValue: PurchaseSubmissionViewModel(purchaseService: purchaseService))
    }

    var body: some View {
        PurchaseConfirmationScreenContainer {
            VStack(alignment: .leading, spacing: PurchaseConfirmationMetrics.verticalSectionSpacing) {
                Text("confirmation.title")
                    .font(AppTypography.bold(PurchaseConfirmationMetrics.cardTitleSize))
                    .foregroundStyle(AppTheme.primaryText)

                Divider()

                DetailLineRow(
                    title: String(localized: "confirmation.vehicle"),
                    value: scenario.vehiclePlate.uppercased(),
                    emphasizedTitle: false,
                    size: PurchaseConfirmationMetrics.rowTextSize
                )
                DetailLineRow(
                    title: String(localized: "confirmation.product"),
                    value: scenario.productSummary,
                    emphasizedTitle: false,
                    size: PurchaseConfirmationMetrics.rowTextSize
                )

                if !scenario.detailRows.isEmpty {
                    Divider()

                    ForEach(scenario.detailRows) { row in
                        DetailLineRow(
                            title: row.title,
                            value: row.value,
                            emphasizedTitle: row.emphasizedTitle,
                            size: PurchaseConfirmationMetrics.rowTextSize
                        )
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: Metrics.totalSectionSpacing) {
                    Text(scenario.totalLabel)
                        .font(AppTypography.bold(PurchaseConfirmationMetrics.totalLabelSize))
                        .foregroundStyle(AppTheme.primaryText)
                    Text(scenario.totalPriceText)
                        .font(AppTypography.bold(PurchaseConfirmationMetrics.totalValueSize))
                        .foregroundStyle(AppTheme.primaryText)
                }

                Spacer(minLength: 0)

                PrimaryActionButton(
                    title: "county.button.next",
                    isEnabled: scenario.isSubmittable,
                    isLoading: submissionViewModel.isSubmitting
                ) {
                    submissionViewModel.submit(items: scenario.orderItems)
                }
                .padding(.top, PurchaseConfirmationMetrics.buttonTopPadding)
                .disabled(!scenario.isSubmittable)
                .accessibilityIdentifier("confirmation.primaryButton")

                SecondaryActionButton(title: "common.button.cancel") {
                    dismiss()
                }
                .padding(.top, PurchaseConfirmationMetrics.buttonSpacing)
            }
        }
        .eVignetteNavigationBar()
        .navigationDestination(isPresented: $submissionViewModel.showResult) {
            if let orderResult = submissionViewModel.orderResult {
                OrderResultScreen(payload: orderResult)
            }
        }
    }
}

#Preview("National Purchase Confirmation") {
    NavigationStack {
        PurchaseConfirmationScreen(
            scenario: .national(
                vignette: NationalVignetteOption(from: HighwayVignette(vignetteType: ["WEEK"], vehicleCategory: "CAR", cost: 6400, trxFee: 200, sum: 6600))!,
                vehiclePlate: "abc-123",
                orderCategory: "CAR"
            ),
            purchaseService: DefaultPurchaseService(apiClient: MockHighwayAPIClient())
        )
    }
}

#Preview("County Purchase Confirmation") {
    NavigationStack {
        PurchaseConfirmationScreen(
            scenario: .county(
                selectedCounties: [
                    CountyVignetteOption(id: "YEAR_12", name: "Baranya", price: 6860),
                    CountyVignetteOption(id: "YEAR_25", name: "Szabolcs-Szatmar-Bereg", price: 6860),
                ],
                vehiclePlate: "abc-123",
                orderCategory: "CAR"
            ),
            purchaseService: DefaultPurchaseService(apiClient: MockHighwayAPIClient())
        )
    }
}
