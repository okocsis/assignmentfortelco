import SwiftUI

struct VignetteHomeScreen: View {
    @State private var viewModel: VignetteViewModel
    private let dependencies: AppDependencies
    @State private var selectedNationalType: String?

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModel = State(initialValue: VignetteViewModel(dependencies: dependencies))
    }

    private enum HomeMetrics {
        static let pageContentSpacing: CGFloat = FigmaConstants.spacings.mediumLargePadding
        static let pageHorizontalPadding: CGFloat = FigmaConstants.spacings.mediumPadding
        static let pageTopPadding: CGFloat = FigmaConstants.spacings.mediumPadding
        static let pageBottomPadding: CGFloat = FigmaConstants.spacings.xLargePadding

        static let cardGroupSpacing: CGFloat = FigmaConstants.spacings.mediumPadding
        static let nationalCardSpacing: CGFloat = FigmaConstants.spacings.mediumSmallPadding
        static let cardPadding: CGFloat = FigmaConstants.spacings.mediumPadding
        static let nationalOptionSpacing: CGFloat = FigmaConstants.spacings.regularPadding
        static let nationalOptionHorizontalPadding: CGFloat = FigmaConstants.spacings.regularPadding
        static let nationalOptionVerticalPadding: CGFloat = FigmaConstants.spacings.mediumPadding
        static let nationalOptionStrokeWidth: CGFloat = FigmaConstants.controls.borderWidth
        static let nationalOptionCornerRadius: CGFloat = FigmaConstants.cornerRadii.optionRow
        static let nationalOuterSelectorSize: CGFloat = FigmaConstants.controls.radioOuterSize
        static let nationalInnerSelectorSize: CGFloat = FigmaConstants.controls.radioInnerSize

        static let vehicleRowSpacing: CGFloat = FigmaConstants.spacings.mediumSmallPadding
        static let vehicleTextSpacing: CGFloat = FigmaConstants.spacings.xSmallPadding
        static let vehicleIconSize: CGFloat = 28
        static let vehicleIconFrameSize: CGFloat = 52
        static let vehicleMinHeight: CGFloat = 72

        static let sectionTitleSize: CGFloat = FigmaConstants.typography.headingSize
        static let errorTextSize: CGFloat = FigmaConstants.typography.errorSize
        static let vehiclePlateSize: CGFloat = FigmaConstants.typography.headingSize
        static let vehicleNameSize: CGFloat = FigmaConstants.typography.bodySize
        static let optionTitleSize: CGFloat = FigmaConstants.typography.bodySize
        static let optionPriceSize: CGFloat = FigmaConstants.typography.bodySize
        static let countyRowChevronSize: CGFloat = FigmaConstants.typography.buttonLabelSize
        static let countyRowTitleSize: CGFloat = FigmaConstants.typography.headingSize

        static let countyRowHorizontalPadding: CGFloat = FigmaConstants.spacings.mediumPadding
        static let countyRowVerticalPadding: CGFloat = FigmaConstants.spacings.largePadding
        static let countyRowMinHeight: CGFloat = 72
    }

    var body: some View {
        ScrollPageScaffold(
            spacing: HomeMetrics.pageContentSpacing,
            horizontalPadding: HomeMetrics.pageHorizontalPadding,
            topPadding: HomeMetrics.pageTopPadding,
            bottomPadding: HomeMetrics.pageBottomPadding,
            alignment: .leading
        ) {
            homeCard
            countyRow
        }
        .eVignetteNavigationBar()
        .task {
            guard viewModel.vehicle == nil || viewModel.highwayInfo == nil else { return }
            await viewModel.load()
            if selectedNationalType == nil {
                selectedNationalType = viewModel.nationalVignettes.first?.type
            }
        }
    }

    private var homeCard: some View {
        VStack(alignment: .leading, spacing: HomeMetrics.cardGroupSpacing) {
            vehicleCard
            nationalVignettesCard
        }
    }

    private var nationalVignettesCard: some View {
        SectionCard(
            alignment: .leading,
            spacing: HomeMetrics.nationalCardSpacing,
            padding: HomeMetrics.cardPadding,
            cornerRadius: AppTheme.cornerMedium
        ) {
            Text("home.section.national_vignettes")
                .font(AppTypography.bold(HomeMetrics.sectionTitleSize))
                .foregroundStyle(AppTheme.primaryText)

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, FigmaConstants.spacings.largePadding)
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(AppTypography.medium(HomeMetrics.errorTextSize))
                    .foregroundStyle(.red)
            } else {
                ForEach(viewModel.nationalVignettes) { vignette in
                    nationalOptionRow(vignette)
                }
            }

            if let selectedVignette = viewModel.selectedNationalVignette(type: selectedNationalType) {
                NavigationLink {
                    PurchaseConfirmationScreen(
                        scenario: .national(
                            vignette: selectedVignette,
                            vehiclePlate: viewModel.vehicle?.plate ?? "",
                            orderCategory: viewModel.orderCategory
                        ),
                        purchaseService: dependencies.purchaseService
                    )
                } label: {
                    PrimaryActionButtonLabel(title: "common.button.purchase")
                }
                .buttonStyle(.plain)
            } else {
                Button {} label: {
                    PrimaryActionButtonLabel(title: "common.button.purchase", isEnabled: false)
                }
                .disabled(true)
            }
        }
    }

    private var vehicleCard: some View {
        SectionCard(
            alignment: .leading,
            spacing: 0,
            padding: HomeMetrics.cardPadding,
            cornerRadius: AppTheme.cornerSmall
        ) {
            HStack(spacing: HomeMetrics.vehicleRowSpacing) {
                Image(systemName: "car.fill")
                    .font(AppTypography.semibold(HomeMetrics.vehicleIconSize))
                    .foregroundStyle(AppTheme.primaryText)
                    .frame(width: HomeMetrics.vehicleIconFrameSize, height: HomeMetrics.vehicleIconFrameSize)

                VStack(alignment: .leading, spacing: HomeMetrics.vehicleTextSpacing) {
                    Text((viewModel.vehicle?.plate ?? "null").uppercased())
                        .font(AppTypography.bold(HomeMetrics.vehiclePlateSize))
                        .foregroundStyle(AppTheme.primaryText)
                    Text(viewModel.vehicle?.name ?? "null")
                        .font(AppTypography.regular(HomeMetrics.vehicleNameSize))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                Spacer()
            }
            .frame(minHeight: HomeMetrics.vehicleMinHeight)
        }
    }

    private func nationalOptionRow(_ vignette: NationalVignetteOption) -> some View {
        let isSelected = selectedNationalType == vignette.type

        return SelectablePriceRow(
            title: vignette.displayName,
            value: vignette.priceText,
            titleFont: AppTypography.semibold(HomeMetrics.optionTitleSize),
            valueFont: AppTypography.bold(HomeMetrics.optionPriceSize),
            titleColor: AppTheme.primaryText,
            valueColor: AppTheme.primaryText,
            spacing: HomeMetrics.nationalOptionSpacing,
            spacerMinLength: FigmaConstants.spacings.smallPadding,
            verticalPadding: HomeMetrics.nationalOptionVerticalPadding,
            minHeight: 0
        ) {
            selectedNationalType = vignette.type
        } leading: {
            RadioSelectionIndicator(
                isSelected: isSelected,
                outerSize: HomeMetrics.nationalOuterSelectorSize,
                innerSize: HomeMetrics.nationalInnerSelectorSize,
                borderWidth: HomeMetrics.nationalOptionStrokeWidth,
                unselectedBorderColor: Color.figmaFillUV5OR5,
                selectedFillColor: AppTheme.primaryText
            )
        }
        .padding(.horizontal, HomeMetrics.nationalOptionHorizontalPadding)
        .background(AppTheme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: HomeMetrics.nationalOptionCornerRadius)
                .stroke(isSelected ? AppTheme.primaryText : Color.figmaFillUV5OR5, lineWidth: HomeMetrics.nationalOptionStrokeWidth)
        )
        .clipShape(.rect(cornerRadius: HomeMetrics.nationalOptionCornerRadius))
    }

    private var countyRow: some View {
        NavigationLink {
            CountySelectionScreen(
                viewModel: CountySelectionViewModel(input: viewModel.countySelectionInput),
                purchaseService: dependencies.purchaseService
            )
        } label: {
            ChevronNavigationRowLabel(
                title: "home.section.county_vignettes",
                titleFont: AppTypography.bold(HomeMetrics.countyRowTitleSize),
                chevronFont: AppTypography.bold(HomeMetrics.countyRowChevronSize),
                horizontalPadding: HomeMetrics.countyRowHorizontalPadding,
                verticalPadding: HomeMetrics.countyRowVerticalPadding,
                minHeight: HomeMetrics.countyRowMinHeight,
                cornerRadius: AppTheme.cornerMedium
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home.countyFlowButton")
    }
}

#Preview {
    VignetteHomeScreen(dependencies: .mock)
}
