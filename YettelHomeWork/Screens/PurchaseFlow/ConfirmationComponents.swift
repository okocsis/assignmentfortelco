import SwiftUI

struct PurchaseConfirmationDetailRow: Identifiable {
    let id: String
    let title: String
    let value: String
    let emphasizedTitle: Bool
}

struct PurchaseConfirmationScreenContainer<Content: View>: View {
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

struct PurchaseConfirmationPrimaryButton: View {
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

struct PurchaseConfirmationSecondaryButton: View {
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

func purchaseConfirmationLine(title: String, value: String, emphasizedTitle: Bool = false) -> some View {
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

func purchaseConfirmationPriceText(_ amount: Double) -> String {
    let formatted = Int(amount).formatted(.number.grouping(.automatic).locale(.current))
    let template = String(localized: "common.price_huf_format")
    return String(format: template, locale: .current, formatted)
}
