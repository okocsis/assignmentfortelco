//
//  ContentView.swift
//  YettelHomeWork
//
//  Created by Olivér Kocsis on 2026. 04. 17..
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel: VignetteViewModel
    private let dependencies: AppDependencies
    @State private var selectedNationalType: String?

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModel = State(initialValue: VignetteViewModel(dependencies: dependencies))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.pageBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        homeCard
                        countyRow
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
        .task {
            guard viewModel.vehicle == nil || viewModel.highwayInfo == nil else { return }
            await viewModel.load()
            if selectedNationalType == nil {
                selectedNationalType = viewModel.nationalVignettes.first?.type
            }
        }
    }

    private var homeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            vehicleCard
            nationalVignettesCard
        }
    }

    private var nationalVignettesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("home.section.national_vignettes")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.primaryText)

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.red)
            } else {
                ForEach(viewModel.nationalVignettes) { vignette in
                    nationalOptionRow(vignette)
                }
            }

            if let selectedVignette = viewModel.selectedNationalVignette(type: selectedNationalType) {
                NavigationLink {
                    NationalPurchaseConfirmationView(
                        vignette: selectedVignette,
                        vehiclePlate: viewModel.vehicle?.plate ?? "",
                        orderCategory: viewModel.orderCategory,
                        purchaseService: dependencies.purchaseService
                    )
                } label: {
                    Text("common.button.purchase")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    .background(AppTheme.primaryButton)
                        .clipShape(.capsule)
                }
                .buttonStyle(.plain)
            } else {
                Button {} label: {
                    Text("common.button.purchase")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.primaryButton.opacity(0.45))
                        .clipShape(.capsule)
                }
                .disabled(true)
            }
        }
        .padding(16)
        .background(AppTheme.surface)
        .clipShape(.rect(cornerRadius: 18))
    }

    private var vehicleCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "car.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(AppTheme.primaryText)
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text((viewModel.vehicle?.plate ?? "ABC 123").uppercased())
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
                Text(viewModel.vehicle?.name ?? "Michael Scott")
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            Spacer()
        }
        .frame(minHeight: 72)
        .padding(16)
        .background(AppTheme.surface)
        .clipShape(.rect(cornerRadius: AppTheme.cornerSmall))
    }

    private func nationalOptionRow(_ vignette: NationalVignetteOption) -> some View {
        let isSelected = selectedNationalType == vignette.type

        return Button {
            selectedNationalType = vignette.type
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(Color.figmaFillUV5OR5, lineWidth: 2)
                        .frame(width: 34, height: 34)
                    if isSelected {
                        Circle()
                            .fill(AppTheme.primaryText)
                            .frame(width: 19, height: 19)
                    }
                }

                Text(vignette.displayName)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)

                Spacer(minLength: 8)

                Text(vignette.priceText)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
            .background(AppTheme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(isSelected ? AppTheme.primaryText : Color.figmaFillUV5OR5, lineWidth: 2)
            )
            .clipShape(.rect(cornerRadius: 7))
        }
        .buttonStyle(.plain)
    }

    private var countyRow: some View {
        NavigationLink {
            CountySelectionView(
                viewModel: CountySelectionViewModel(input: viewModel.countySelectionInput),
                purchaseService: dependencies.purchaseService
            )
        } label: {
            HStack {
                Text("home.section.county_vignettes")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.primaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .frame(minHeight: 72)
            .background(AppTheme.surface)
            .clipShape(.rect(cornerRadius: AppTheme.cornerMedium))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home.countyFlowButton")
    }
}

#Preview {
    ContentView(dependencies: .live)
}
