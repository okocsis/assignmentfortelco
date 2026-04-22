import Observation
import SwiftUI

struct NationalPurchaseConfirmationView: View {
    let vignette: NationalVignetteOption
    let vehiclePlate: String
    let orderCategory: String
    @Environment(\.dismiss) private var dismiss
    @State private var submissionViewModel: PurchaseSubmissionViewModel

    init(
        vignette: NationalVignetteOption,
        vehiclePlate: String,
        orderCategory: String,
        purchaseService: PurchaseService
    ) {
        self.vignette = vignette
        self.vehiclePlate = vehiclePlate
        self.orderCategory = orderCategory
        _submissionViewModel = State(initialValue: PurchaseSubmissionViewModel(purchaseService: purchaseService))
    }

    var body: some View {
        ConfirmationScreenContainer {
            VStack(alignment: .leading, spacing: ConfirmationScreenMetrics.verticalSectionSpacing) {
                Text("confirmation.title")
                    .font(.system(size: ConfirmationScreenMetrics.cardTitleSize, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)

                Divider()

                confirmationLine(title: String(localized: "confirmation.vehicle"), value: vehiclePlate.uppercased())
                confirmationLine(title: String(localized: "confirmation.product"), value: vignette.displayName)

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("confirmation.total")
                        .font(.system(size: ConfirmationScreenMetrics.totalLabelSize, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText)
                    Text(vignette.priceText)
                        .font(.system(size: ConfirmationScreenMetrics.totalValueSize, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText)
                }

                Spacer(minLength: 0)

                ConfirmationPrimaryButton(isSubmitting: submissionViewModel.isSubmitting) {
                    submitOrder()
                }

                ConfirmationSecondaryButton {
                    dismiss()
                }
            }
        }
        .navigationTitle(String(localized: "common.title.e_vignette"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.accentLime, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationDestination(isPresented: $submissionViewModel.showResult) {
            if let orderResult = submissionViewModel.orderResult {
                OrderResultView(payload: orderResult)
            }
        }
    }

    private func submitOrder() {
        let item = OrderItem(type: vignette.type, category: orderCategory, cost: vignette.sum)
        submissionViewModel.submit(items: [item])
    }
}

struct CountyPurchaseConfirmationView: View {
    let selectedCounties: [CountyVignetteOption]
    let vehiclePlate: String
    let orderCategory: String
    @Environment(\.dismiss) private var dismiss
    @State private var submissionViewModel: PurchaseSubmissionViewModel

    init(
        selectedCounties: [CountyVignetteOption],
        vehiclePlate: String,
        orderCategory: String,
        purchaseService: PurchaseService
    ) {
        self.selectedCounties = selectedCounties
        self.vehiclePlate = vehiclePlate
        self.orderCategory = orderCategory
        _submissionViewModel = State(initialValue: PurchaseSubmissionViewModel(purchaseService: purchaseService))
    }

    private var totalPriceText: String {
        let total = selectedCounties.reduce(0) { $0 + $1.price }
        return formatPrice(total)
    }

    var body: some View {
        ConfirmationScreenContainer {
            VStack(alignment: .leading, spacing: ConfirmationScreenMetrics.verticalSectionSpacing) {
                Text("confirmation.title")
                    .font(.system(size: ConfirmationScreenMetrics.cardTitleSize, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)

                Divider()

                confirmationLine(title: String(localized: "confirmation.vehicle"), value: vehiclePlate.uppercased())
                confirmationLine(
                    title: String(localized: "confirmation.product"),
                    value: String(format: String(localized: "confirmation.county_count"), locale: .current, selectedCounties.count)
                )

                Divider()

                ForEach(selectedCounties) { county in
                    confirmationLine(title: county.name, value: county.priceText, emphasizedTitle: true)
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("county.total_price.label")
                        .font(.system(size: ConfirmationScreenMetrics.totalLabelSize, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText)
                    Text(totalPriceText)
                        .font(.system(size: ConfirmationScreenMetrics.totalValueSize, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText)
                }

                Spacer(minLength: 0)

                ConfirmationPrimaryButton(isSubmitting: submissionViewModel.isSubmitting) {
                    submitOrder()
                }
                .disabled(selectedCounties.isEmpty)

                ConfirmationSecondaryButton {
                    dismiss()
                }
            }
        }
        .navigationTitle(String(localized: "common.title.e_vignette"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.accentLime, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationDestination(isPresented: $submissionViewModel.showResult) {
            if let orderResult = submissionViewModel.orderResult {
                OrderResultView(payload: orderResult)
            }
        }
    }

    private func submitOrder() {
        let items = selectedCounties.map {
            OrderItem(type: $0.id, category: orderCategory, cost: $0.price)
        }
        submissionViewModel.submit(items: items)
    }
}

struct OrderResultView: View {
    let payload: PurchaseResultPayload
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            (payload.isSuccess ? AppTheme.accentLime : AppTheme.pageBackground)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                if payload.isSuccess {
                    celebrationConfetti

                    Text("result.success.message")
                        .font(.system(size: ResultScreenMetrics.successMessageSize, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText)
                        .frame(maxWidth: 280, alignment: .leading)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(2)

                    HStack {
                        Spacer()
                        Image("SuccessIllustration")
                            .resizable()
                            .scaledToFit()
                            .frame(height: ResultScreenMetrics.illustrationHeight)
                            .offset(x: 34)
                    }
                    .layoutPriority(0)
                } else {
                    VStack(alignment: .leading, spacing: 14) {
                        Label {
                            Text("result.failure.title")
                                .font(.system(size: ResultScreenMetrics.failureTitleSize, weight: .bold, design: .rounded))
                        } icon: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 42, weight: .bold))
                        }
                        .foregroundStyle(.red)

                        Text(payload.message.isEmpty ? String(localized: "result.failure.message") : payload.message)
                            .font(.system(size: ResultScreenMetrics.failureMessageSize, weight: .regular, design: .rounded))
                            .foregroundStyle(AppTheme.primaryText.opacity(0.8))

                        Button {
                            dismiss()
                        } label: {
                            Text("result.button.retry")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppTheme.primaryButton)
                                .clipShape(.capsule)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(18)
                    .background(AppTheme.surface)
                    .clipShape(.rect(cornerRadius: AppTheme.cornerMedium))
                }

                Spacer(minLength: 0)

                Button {
                    dismiss()
                } label: {
                    Text("result.button.done")
                        .font(.system(size: ResultScreenMetrics.actionButtonSize, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.primaryButton)
                        .clipShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("result.doneButton")
            }
            .padding(.horizontal, ResultScreenMetrics.contentHorizontalPadding)
            .padding(.vertical, ResultScreenMetrics.contentVerticalPadding)
        }
        .navigationTitle(String(localized: "common.title.e_vignette"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(payload.isSuccess ? AppTheme.accentLime : AppTheme.pageBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var celebrationConfetti: some View {
        ZStack(alignment: .top) {
            Image("SuccessConfetti")
                .resizable()
                .scaledToFill()
                .frame(height: ResultScreenMetrics.confettiHeight)
                .frame(maxWidth: .infinity)
                .clipped()
        }
        .padding(.bottom, 4)
    }
}

struct PurchaseResultPayload {
    let isSuccess: Bool
    let message: String

    static func from(response: OrderResponse) -> PurchaseResultPayload {
        let isSuccess = response.statusCode.uppercased() == "OK"
        let message = response.message ?? ""
        return PurchaseResultPayload(isSuccess: isSuccess, message: message)
    }

    static func failure(message: String) -> PurchaseResultPayload {
        PurchaseResultPayload(isSuccess: false, message: message)
    }
}

private struct ConfirmationScreenContainer<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            AppTheme.pageBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("confirmation.navigation_title")
                        .font(.system(size: ConfirmationScreenMetrics.headingSize, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                        .padding(.leading, ConfirmationScreenMetrics.pageHorizontalPadding)
                        .padding(.bottom, 10)

                    VStack(alignment: .leading, spacing: ConfirmationScreenMetrics.verticalSectionSpacing) {
                        content
                    }
                    .padding(.top, ConfirmationScreenMetrics.contentTopPadding)
                    .padding(.horizontal, ConfirmationScreenMetrics.contentHorizontalPadding)
                    .padding(.bottom, ConfirmationScreenMetrics.contentTopPadding)
                    .background(AppTheme.surface)
                    .clipShape(.rect(cornerRadius: AppTheme.cornerMedium))
                }
                .padding(.horizontal, ConfirmationScreenMetrics.pageHorizontalPadding)
                .padding(.top, ConfirmationScreenMetrics.pageTopPadding)
                .padding(.bottom, ConfirmationScreenMetrics.pageBottomPadding)
            }
        }
    }
}

private struct ConfirmationPrimaryButton: View {
    let isSubmitting: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if isSubmitting {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.primaryButton)
                    .clipShape(.capsule)
            } else {
                Text("county.button.next")
                    .font(.system(size: ConfirmationScreenMetrics.primaryButtonSize, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.primaryButton)
                    .clipShape(.capsule)
            }
        }
        .buttonStyle(.plain)
        .disabled(isSubmitting)
        .padding(.top, ConfirmationScreenMetrics.buttonTopPadding)
        .accessibilityIdentifier("confirmation.primaryButton")
    }
}

private struct ConfirmationSecondaryButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("common.button.cancel")
                .font(.system(size: ConfirmationScreenMetrics.primaryButtonSize, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.primaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .overlay(
                    Capsule()
                        .stroke(AppTheme.primaryButton, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
        .padding(.top, ConfirmationScreenMetrics.buttonSpacing)
    }
}

private func confirmationLine(title: String, value: String, emphasizedTitle: Bool = false) -> some View {
    HStack {
        Text(title)
            .font(.system(size: ConfirmationScreenMetrics.rowTextSize, weight: emphasizedTitle ? .bold : .regular, design: .rounded))
            .foregroundStyle(AppTheme.primaryText)
        Spacer()
        Text(value)
            .font(.system(size: ConfirmationScreenMetrics.rowTextSize, weight: .medium, design: .rounded))
            .foregroundStyle(AppTheme.primaryText)
    }
}

private func formatPrice(_ amount: Double) -> String {
    let formatted = Int(amount).formatted(.number.grouping(.automatic).locale(.current))
    let template = String(localized: "common.price_huf_format")
    return String(format: template, locale: .current, formatted)
}
