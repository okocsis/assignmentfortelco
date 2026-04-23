import Foundation
import Observation
import SwiftUI

struct CountySelectionScreen: View {
    @Bindable var viewModel: CountySelectionViewModel
    let purchaseService: PurchaseService

    private enum CountyMetrics {
        static let pageVerticalSpacing: CGFloat = FigmaConstants.spacings.mediumPadding
        static let pageHorizontalPadding: CGFloat = FigmaConstants.spacings.mediumPadding
        static let pageTopPadding: CGFloat = FigmaConstants.spacings.xxLargePadding
        static let pageBottomPadding: CGFloat = FigmaConstants.spacings.xLargePadding

        static let cardPadding: CGFloat = FigmaConstants.spacings.mediumPadding
        static let titleToMapSpacing: CGFloat = FigmaConstants.spacings.mediumPadding
        static let mapToWarningSpacing: CGFloat = FigmaConstants.spacings.smallPadding
        static let mapToListSpacing: CGFloat = FigmaConstants.spacings.mediumPadding
        static let warningToListSpacing: CGFloat = FigmaConstants.spacings.mediumPadding
        static let listToTotalSpacing: CGFloat = FigmaConstants.spacings.mediumPadding
        static let totalLabelToValueSpacing: CGFloat = FigmaConstants.spacings.xSmallPadding
        static let totalToButtonSpacing: CGFloat = FigmaConstants.spacings.largePadding

        static let titleSize: CGFloat = FigmaConstants.typography.headingSize
        static let warningSize: CGFloat = FigmaConstants.typography.labelSize
        static let totalLabelSize: CGFloat = FigmaConstants.typography.labelSize
        static let totalValueSize: CGFloat = FigmaConstants.typography.displaySize
        static let rowSpacing: CGFloat = FigmaConstants.spacings.mediumSmallPadding
        static let rowVerticalPadding: CGFloat = FigmaConstants.spacings.smallPadding
        static let rowMinHeight: CGFloat = 24
        static let rowIconSize: CGFloat = FigmaConstants.controls.checkboxIconSize
        static let rowTextSize: CGFloat = FigmaConstants.typography.bodySize
        static let rowPriceSize: CGFloat = FigmaConstants.typography.bodySize
    }

    var body: some View {
        ScrollPageScaffold(
            spacing: CountyMetrics.pageVerticalSpacing,
            horizontalPadding: CountyMetrics.pageHorizontalPadding,
            topPadding: CountyMetrics.pageTopPadding,
            bottomPadding: CountyMetrics.pageBottomPadding,
            alignment: .leading,
            backgroundColor: AppTheme.surface
        ) {
            countyCard
        }
        .eVignetteNavigationBar()
    }

    private var countyCard: some View {
        SectionCard(
            alignment: .leading,
            spacing: 0,
            padding: CountyMetrics.cardPadding,
            cornerRadius: 0
        ) {
            Text("county.section.title")
                .font(AppTypography.bold(CountyMetrics.titleSize))
                .foregroundStyle(AppTheme.primaryText)

            CountyMapView(
                counties: viewModel.input.countyVignettes,
                mapShapes: viewModel.input.countyShapesByVignetteType,
                selectedCountyIDs: viewModel.selectedCountyIDs,
                onToggle: viewModel.toggleCountySelection
            )
            .padding(.top, CountyMetrics.titleToMapSpacing)

            if let connectivityWarning = viewModel.connectivityWarning {
                Text(connectivityWarning)
                    .font(AppTypography.medium(CountyMetrics.warningSize))
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("county.warning.disconnected")
                    .padding(.top, CountyMetrics.mapToWarningSpacing)
            }

            VStack(spacing: 0) {
                ForEach(viewModel.input.countyVignettes) { county in
                    countyRow(county)
                }
            }
            .padding(.top, viewModel.connectivityWarning == nil ? CountyMetrics.mapToListSpacing : CountyMetrics.warningToListSpacing)

            VStack(alignment: .leading, spacing: CountyMetrics.totalLabelToValueSpacing) {
                Divider()

                Text("county.total_price.label")
                    .font(AppTypography.bold(CountyMetrics.totalLabelSize))
                    .foregroundStyle(AppTheme.primaryText)

                Text(viewModel.totalPriceText)
                    .font(AppTypography.bold(CountyMetrics.totalValueSize))
                    .foregroundStyle(Color(red: 0.02, green: 0.15, blue: 0.28))
                    .accessibilityIdentifier("county.totalValue")
            }
            .padding(.top, CountyMetrics.listToTotalSpacing)

            if !viewModel.canProceed {
                Button {} label: {
                    PrimaryActionButtonLabel(title: "county.button.next", isEnabled: false)
                }
                .disabled(true)
                .accessibilityIdentifier("county.nextButton")
                .padding(.top, CountyMetrics.totalToButtonSpacing)
            } else {
                NavigationLink {
                    PurchaseConfirmationScreen(
                        scenario: .county(
                            selectedCounties: viewModel.selectedCounties,
                            vehiclePlate: viewModel.input.vehiclePlate,
                            orderCategory: viewModel.input.orderCategory
                        ),
                        purchaseService: purchaseService
                    )
                } label: {
                    PrimaryActionButtonLabel(title: "county.button.next")
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("county.nextButton")
                .padding(.top, CountyMetrics.totalToButtonSpacing)
            }
        }
    }

    private func countyRow(_ county: CountyVignetteOption) -> some View {
        let isSelected = viewModel.selectedCountyIDs.contains(county.id)

        return SelectablePriceRow(
            title: county.name,
            value: county.priceText,
            titleFont: AppTypography.regular(CountyMetrics.rowTextSize),
            valueFont: AppTypography.bold(CountyMetrics.rowPriceSize),
            titleColor: isSelected ? Color.figmaFillXD9P3M : AppTheme.primaryText,
            valueColor: AppTheme.primaryText,
            spacing: CountyMetrics.rowSpacing,
            spacerMinLength: FigmaConstants.spacings.smallPadding,
            verticalPadding: CountyMetrics.rowVerticalPadding,
            minHeight: CountyMetrics.rowMinHeight
        ) {
            viewModel.toggleCountySelection(county.id)
        } leading: {
            CheckboxSelectionIndicator(
                isSelected: isSelected,
                size: CountyMetrics.rowIconSize,
                selectedColor: Color.figmaFillXD9P3M,
                unselectedColor: Color.figmaFillUV5OR5
            )
        }
        .accessibilityLabel("\(county.name), \(county.priceText)")
        .accessibilityIdentifier("county.row.\(county.id)")
        .accessibilityValue(isSelected ? "selected" : "not_selected")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }
}

#Preview {
    CountySelectionScreen(
        viewModel: CountySelectionViewModel(
            input: CountySelectionInput(
                countyVignettes: [],
                countyVignettePrice: 0,
                countyAdjacencyByVignetteType: [:],
                countyShapesByVignetteType: [:],
                orderCategory: "",
                vehiclePlate: ""
            )
        ),
        purchaseService: DefaultPurchaseService(
            apiClient: MockHighwayAPIClient()
        )
    )
}
