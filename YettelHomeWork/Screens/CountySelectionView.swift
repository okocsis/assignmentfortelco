import Foundation
import Observation
import SwiftUI

struct CountySelectionView: View {
    @Bindable var viewModel: CountySelectionViewModel
    let purchaseService: PurchaseService

    var body: some View {
        ZStack {
            AppTheme.pageBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    countyCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle(String(localized: "common.title.e_vignette"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.accentLime, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var countyCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("county.section.title")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.primaryText)

            CountyMapView(
                counties: viewModel.input.countyVignettes,
                mapShapes: viewModel.input.countyShapesByVignetteType,
                selectedCountyIDs: viewModel.selectedCountyIDs,
                onToggle: viewModel.toggleCountySelection
            )
            .padding(.bottom, 6)

            if let connectivityWarning = viewModel.connectivityWarning {
                Text(connectivityWarning)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.red)
            }

            VStack(spacing: 0) {
                ForEach(viewModel.input.countyVignettes) { county in
                    countyRow(county)
                }
            }

            Divider()
                .padding(.top, 4)

            Text("county.total_price.label")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.primaryText)

            Text(viewModel.totalPriceText)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.02, green: 0.15, blue: 0.28))

            if !viewModel.canProceed {
                Button {} label: {
                    Text("county.button.next")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                .background(AppTheme.primaryButton.opacity(0.45))
                        .clipShape(.capsule)
                }
                .disabled(true)
            } else {
                NavigationLink {
                    CountyPurchaseConfirmationView(
                        selectedCounties: viewModel.selectedCounties,
                        vehiclePlate: viewModel.input.vehiclePlate,
                        orderCategory: viewModel.input.orderCategory,
                        purchaseService: purchaseService
                    )
                } label: {
                    Text("county.button.next")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.primaryButton)
                        .clipShape(.capsule)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(AppTheme.surface)
        .clipShape(.rect(cornerRadius: AppTheme.cornerMedium))
    }

    private func countyRow(_ county: CountyVignetteOption) -> some View {
        let isSelected = viewModel.selectedCountyIDs.contains(county.id)

        return Button {
            viewModel.toggleCountySelection(county.id)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(isSelected ? Color.figmaFillXD9P3M : Color.figmaFillUV5OR5)

                Text(county.name)
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .foregroundStyle(isSelected ? Color.figmaFillXD9P3M : AppTheme.primaryText)

                Spacer()

                Text(county.priceText)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
            }
            .padding(.vertical, 9)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(county.name), \(county.priceText)")
        .accessibilityIdentifier("county.row.\(county.id)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }
}
