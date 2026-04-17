//
//  ContentView.swift
//  YettelHomeWork
//
//  Created by Olivér Kocsis on 2026. 04. 17..
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = HomeViewModel()
    @State private var selectedNationalType: String?

    var body: some View {
        ZStack {
            Color(red: 0.84, green: 0.83, blue: 0.90)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Highway")
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 0.36, green: 0.35, blue: 0.42))

                    headerBar
                    homeCard
                    countyRow
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        .task {
            guard viewModel.vehicle == nil || viewModel.highwayInfo == nil else { return }
            await viewModel.load()
            if selectedNationalType == nil {
                selectedNationalType = viewModel.nationalVignettes.first?.type
            }
        }
    }

    private var headerBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.left")
                .font(.system(size: 18, weight: .regular))
            Text("E-matrica")
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Spacer(minLength: 0)
        }
        .foregroundStyle(Color(red: 0.02, green: 0.15, blue: 0.28))
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .background(Color(red: 0.73, green: 1.00, blue: 0.00))
        .clipShape(.rect(cornerRadius: 24))
    }

    private var homeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            vehicleCard

            VStack(alignment: .leading, spacing: 12) {
                Text("Orszagos matricak")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.02, green: 0.15, blue: 0.28))

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

                Button {
                } label: {
                    Text("Vasarlas")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.02, green: 0.15, blue: 0.28))
                        .clipShape(.capsule)
                }
            }
            .padding(16)
            .background(Color.white)
            .clipShape(.rect(cornerRadius: 18))
        }
        .padding(14)
        .background(Color(red: 0.91, green: 0.91, blue: 0.93))
        .clipShape(.rect(cornerRadius: 18))
    }

    private var vehicleCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "car.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color(red: 0.02, green: 0.15, blue: 0.28))
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text((viewModel.vehicle?.plate ?? "ABC 123").uppercased())
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.02, green: 0.15, blue: 0.28))
                Text(viewModel.vehicle?.name ?? "Michael Scott")
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .foregroundStyle(Color(red: 0.20, green: 0.27, blue: 0.34))
            }
            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .clipShape(.rect(cornerRadius: 14))
    }

    private func nationalOptionRow(_ vignette: NationalVignetteOption) -> some View {
        let isSelected = selectedNationalType == vignette.type

        return Button {
            selectedNationalType = vignette.type
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(Color(red: 0.82, green: 0.84, blue: 0.87), lineWidth: 3)
                        .frame(width: 34, height: 34)
                    if isSelected {
                        Circle()
                            .fill(Color(red: 0.02, green: 0.15, blue: 0.28))
                            .frame(width: 19, height: 19)
                    }
                }

                Text(vignette.displayName)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 0.02, green: 0.15, blue: 0.28))

                Spacer(minLength: 8)

                Text(vignette.priceText)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.02, green: 0.15, blue: 0.28))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 11)
                    .stroke(isSelected ? Color(red: 0.02, green: 0.15, blue: 0.28) : Color(red: 0.82, green: 0.84, blue: 0.87), lineWidth: 3)
            )
            .clipShape(.rect(cornerRadius: 11))
        }
        .buttonStyle(.plain)
    }

    private var countyRow: some View {
        HStack {
            Text("Eves varmegyei matricak")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.02, green: 0.15, blue: 0.28))
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color(red: 0.02, green: 0.15, blue: 0.28))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(Color.white)
        .clipShape(.rect(cornerRadius: 18))
    }
}

#Preview {
    ContentView()
}
