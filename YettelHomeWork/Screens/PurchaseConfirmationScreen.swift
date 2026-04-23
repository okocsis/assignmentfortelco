import SwiftUI

enum PurchaseConfirmationMetrics {
    static let navigationHeadingSize: CGFloat = 46
    static let cardTitleSize: CGFloat = 28
    static let rowTextSize: CGFloat = FigmaConstants.typography.buttonLabelSize
    static let totalLabelSize: CGFloat = FigmaConstants.typography.bodySize
    static let totalValueSize: CGFloat = 50
    static let verticalSectionSpacing: CGFloat = FigmaConstants.spacings.mediumPadding
    static let pageHorizontalPadding: CGFloat = FigmaConstants.spacings.mediumPadding
    static let pageTopPadding: CGFloat = FigmaConstants.spacings.xxLargePadding
    static let pageBottomPadding: CGFloat = FigmaConstants.spacings.xLargePadding
    static let contentTopPadding: CGFloat = FigmaConstants.spacings.mediumPadding
    static let contentHorizontalPadding: CGFloat = FigmaConstants.spacings.mediumPadding
    static let headingBottomPadding: CGFloat = 10
    static let buttonTopPadding: CGFloat = FigmaConstants.spacings.largePadding
    static let buttonSpacing: CGFloat = FigmaConstants.spacings.regularPadding
}

enum PurchaseConfirmationScenario {
    
    struct DetailRow: Identifiable {
        let id: String
        let title: String
        let value: String
        let emphasizedTitle: Bool
    }
    
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
        case .county:
            String(localized: "confirmation.county_count")
        }
    }

    var detailRows: [DetailRow] {
        switch self {
        case let .national(vignette, _, _):

            return [
                DetailRow(
                    id: vignette.id,
                    title: vignette.displayName,
                    value: Self.localizedPriceText(for: vignette.cost),
                    emphasizedTitle: true
                ),
                DetailRow(
                    id: "transaction_fee_total",
                    title: String(localized: "confirmation.transaction_fee"),
                    value: Self.localizedPriceText(for: vignette.trxFee),
                    emphasizedTitle: false
                ),
            ]
        case let .county(selectedCounties, _, _):
            var rows = selectedCounties.map {
                DetailRow(
                    id: $0.id,
                    title: $0.name,
                    value: $0.priceText,
                    emphasizedTitle: true
                )
            }

            let transactionFeeTotal = selectedCounties.reduce(0) {
                $0 + $1.trxFee
            }
            rows.append(
                DetailRow(
                    id: "transaction_fee_total",
                    title: String(localized: "confirmation.transaction_fee"),
                    value: Self.localizedPriceText(for: transactionFeeTotal),
                    emphasizedTitle: false
                )
            )

            return rows
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
            return Self.localizedPriceText(for: vignette.totalPrice)
        case let .county(selectedCounties, _, _):
            let total = selectedCounties.reduce(0) {
                $0 + $1.totalPrice
            }
            return Self.localizedPriceText(for: total)
        }
    }

    var orderItems: [OrderItem] {
        switch self {
        case let .national(vignette, _, orderCategory):
            [
                OrderItem(
                    type: vignette.type,
                    category: orderCategory,
                    cost: vignette.totalPrice
                )
            ]
        case let .county(selectedCounties, _, orderCategory):
            selectedCounties.map {
                OrderItem(
                    type: $0.id,
                    category: orderCategory,
                    cost: $0.totalPrice
                )
            }
        }
    }

    var isSubmittable: Bool {
        !orderItems.isEmpty
    }
    
    static func localizedPriceText(for amount: Double) -> String {
        let formatted = Int(amount).formatted(.number.grouping(.automatic).locale(.current))
        let template = String(localized: "common.price_huf_format")
        return String(format: template, locale: .current, formatted)
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
        ScrollPageScaffold(
            spacing: 0,
            horizontalPadding: PurchaseConfirmationMetrics.pageHorizontalPadding,
            topPadding: PurchaseConfirmationMetrics.pageTopPadding,
            bottomPadding: PurchaseConfirmationMetrics.pageBottomPadding,
            alignment: .leading,
            backgroundColor: AppTheme.surface
        ) {

            SectionCard(
                alignment: .leading,
                spacing: PurchaseConfirmationMetrics.verticalSectionSpacing,
                padding: PurchaseConfirmationMetrics.contentHorizontalPadding,
                cornerRadius: 0
            ) {
                content
            }
            .padding(.top, PurchaseConfirmationMetrics.contentTopPadding)
        }
        .eVignetteNavigationBar()
        .navigationDestination(isPresented: $submissionViewModel.showResult) {
            if let orderResult = submissionViewModel.orderResult {
                OrderResultScreen(payload: orderResult)
            }
        }
    }
    
    private var content: some View {
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
                    .accessibilityIdentifier("confirmation.row.\(row.id)")
                    .accessibilityValue(row.value)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: Metrics.totalSectionSpacing) {
                Text(scenario.totalLabel)
                    .font(AppTypography.bold(PurchaseConfirmationMetrics.totalLabelSize))
                    .foregroundStyle(AppTheme.primaryText)
                    .accessibilityIdentifier("confirmation.totalLabel")
                Text(scenario.totalPriceText)
                    .font(AppTypography.bold(PurchaseConfirmationMetrics.totalValueSize))
                    .foregroundStyle(AppTheme.primaryText)
                    .accessibilityIdentifier("confirmation.totalValue")
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
            .accessibilityIdentifier("confirmation.cancelButton")
            .padding(.top, PurchaseConfirmationMetrics.buttonSpacing)
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
                    CountyVignetteOption(id: "YEAR_12", name: "Baranya", price: 6860, trxFee: 200),
                    CountyVignetteOption(id: "YEAR_25", name: "Szabolcs-Szatmar-Bereg", price: 6860, trxFee: 200),
                ],
                vehiclePlate: "abc-123",
                orderCategory: "CAR"
            ),
            purchaseService: DefaultPurchaseService(apiClient: MockHighwayAPIClient())
        )
    }
}
