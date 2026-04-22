import SwiftUI

enum PurchaseConfirmationMetrics {
    static let navigationHeadingSize: CGFloat = 46
    static let cardTitleSize: CGFloat = 48
    static let rowTextSize: CGFloat = FigmaConstants.typography.buttonLabelSize
    static let totalLabelSize: CGFloat = FigmaConstants.typography.bodySize
    static let totalValueSize: CGFloat = 50
    static let verticalSectionSpacing: CGFloat = FigmaConstants.spacings.mediumPadding
    static let pageHorizontalPadding: CGFloat = FigmaConstants.spacings.mediumPadding
    static let pageTopPadding: CGFloat = FigmaConstants.spacings.mediumPadding
    static let pageBottomPadding: CGFloat = FigmaConstants.spacings.xLargePadding
    static let contentTopPadding: CGFloat = FigmaConstants.spacings.mediumPadding
    static let contentHorizontalPadding: CGFloat = FigmaConstants.spacings.mediumPadding
    static let headingBottomPadding: CGFloat = 10
    static let buttonTopPadding: CGFloat = FigmaConstants.spacings.largePadding
    static let buttonSpacing: CGFloat = FigmaConstants.spacings.regularPadding
}

struct PurchaseConfirmationDetailRow: Identifiable {
    let id: String
    let title: String
    let value: String
    let emphasizedTitle: Bool
}

struct PurchaseConfirmationScreenContainer<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ScrollPageScaffold(
            spacing: 0,
            horizontalPadding: PurchaseConfirmationMetrics.pageHorizontalPadding,
            topPadding: PurchaseConfirmationMetrics.pageTopPadding,
            bottomPadding: PurchaseConfirmationMetrics.pageBottomPadding,
            alignment: .leading
        ) {
            Text("confirmation.navigation_title")
                .font(AppTypography.medium(PurchaseConfirmationMetrics.navigationHeadingSize))
                .foregroundStyle(AppTheme.secondaryText)
                .padding(.leading, PurchaseConfirmationMetrics.pageHorizontalPadding)
                .padding(.bottom, PurchaseConfirmationMetrics.headingBottomPadding)

            SectionCard(
                alignment: .leading,
                spacing: PurchaseConfirmationMetrics.verticalSectionSpacing,
                padding: PurchaseConfirmationMetrics.contentHorizontalPadding,
                cornerRadius: AppTheme.cornerMedium
            ) {
                content
            }
            .padding(.top, PurchaseConfirmationMetrics.contentTopPadding)
        }
    }
}

func purchaseConfirmationPriceText(_ amount: Double) -> String {
    let formatted = Int(amount).formatted(.number.grouping(.automatic).locale(.current))
    let template = String(localized: "common.price_huf_format")
    return String(format: template, locale: .current, formatted)
}
