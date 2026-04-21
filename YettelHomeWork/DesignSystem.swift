import SwiftUI

enum AppTheme {
    static let pageBackground = Color.figmaGrey50
    static let surface = Color.figmaGrey0
    static let cardBackground = Color.figmaGrey0
    static let primaryText = Color.figmaFillUSG1V1
    static let secondaryText = Color.figmaFillXD9P3M
    static let accentLime = Color.figmaPrimaryColorsLime
    static let primaryButton = Color.figmaFillUSG1V1

    static let cornerSmall: CGFloat = 8
    static let cornerMedium: CGFloat = 16
    static let cornerLarge: CGFloat = 20
}

enum ConfirmationScreenMetrics {
    static let headingSize: CGFloat = 46
    static let cardTitleSize: CGFloat = 48
    static let rowTextSize: CGFloat = 16
    static let totalLabelSize: CGFloat = 18
    static let totalValueSize: CGFloat = 50
    static let primaryButtonSize: CGFloat = 22
    static let verticalSectionSpacing: CGFloat = 16
    static let cardPadding: CGFloat = 18
    static let contentHorizontalPadding: CGFloat = 16
    static let pageHorizontalPadding: CGFloat = 16
    static let pageTopPadding: CGFloat = 16
    static let pageBottomPadding: CGFloat = 24
    static let contentTopPadding: CGFloat = 16
    static let buttonTopPadding: CGFloat = 20
    static let buttonSpacing: CGFloat = 14
}

enum ResultScreenMetrics {
    static let successMessageSize: CGFloat = 64
    static let failureTitleSize: CGFloat = 34
    static let failureMessageSize: CGFloat = 18
    static let actionButtonSize: CGFloat = 22
    static let contentHorizontalPadding: CGFloat = 24
    static let contentVerticalPadding: CGFloat = 20
    static let confettiHeight: CGFloat = 240
    static let illustrationHeight: CGFloat = 300
}
