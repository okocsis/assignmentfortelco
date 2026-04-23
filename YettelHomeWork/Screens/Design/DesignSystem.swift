import SwiftUI

enum FigmaConstants {
    enum Spacings {
        static let xSmallPadding: CGFloat = 4
        static let smallPadding: CGFloat = 8
        static let compactRowPadding: CGFloat = 9
        static let mediumSmallPadding: CGFloat = 12
        static let regularPadding: CGFloat = 14
        static let mediumPadding: CGFloat = 16
        static let mediumLargePadding: CGFloat = 18
        static let largePadding: CGFloat = 20
        static let xLargePadding: CGFloat = 24
        static let xxLargePadding: CGFloat = 32
    }

    enum CornerRadii {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 20
        static let optionRow: CGFloat = 7
        static let buttonCapsule: CGFloat = 24
        static let pill: CGFloat = 100
    }

    enum Typography {
        static let errorSize: CGFloat = 10
        static let labelSize: CGFloat = 14
        static let bodySize: CGFloat = 16
        static let headingSize: CGFloat = 20
        static let buttonLabelSize: CGFloat = 20
        static let displaySize: CGFloat = 44
    }

    enum Controls {
        static let borderWidth: CGFloat = 2
        static let radioOuterSize: CGFloat = 34
        static let radioInnerSize: CGFloat = 19
        static let checkboxIconSize: CGFloat = 20
    }

    enum Opacity {
        static let disabled: CGFloat = 0.45
    }

    static let spacings = Spacings.self
    static let cornerRadii = CornerRadii.self
    static let typography = Typography.self
    static let controls = Controls.self
    static let opacity = Opacity.self
}

enum AppFonts {
    static let regular = "Noah-Regular"
    static let bold = "Noah-Bold"
    static let regularItalic = "Noah-RegularItalic"
    static let boldItalic = "Noah-BoldItalic"
}

enum AppTypography {
    static func regular(_ size: CGFloat) -> Font {
        .custom(AppFonts.regular, size: size)
    }

    static func medium(_ size: CGFloat) -> Font {
        .custom(AppFonts.regular, size: size)
    }

    static func semibold(_ size: CGFloat) -> Font {
        .custom(AppFonts.bold, size: size)
    }

    static func bold(_ size: CGFloat) -> Font {
        .custom(AppFonts.bold, size: size)
    }
}

enum AppTheme {
    static let pageBackground = Color.figmaGrey50
    static let surface = Color.figmaGrey0
    static let cardBackground = Color.figmaGrey0
    static let primaryText = Color.figmaFillUSG1V1
    static let secondaryText = Color.figmaFillXD9P3M
    static let accentLime = Color.figmaPrimaryColorsLime
    static let primaryButton = Color.figmaFillUSG1V1

    static let cornerSmall: CGFloat = FigmaConstants.cornerRadii.small
    static let cornerMedium: CGFloat = FigmaConstants.cornerRadii.medium
    static let cornerLarge: CGFloat = FigmaConstants.cornerRadii.large
}
