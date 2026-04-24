import SwiftUI

struct DetailLineRow: View {
    let title: String
    let value: String
    let emphasizedTitle: Bool
    let size: CGFloat
    let accessibilityIdentifier: String

    var body: some View {
        HStack {
            Text(title)
                .font(emphasizedTitle ? AppTypography.bold(size) : AppTypography.regular(size))
                .foregroundStyle(AppTheme.primaryText)
            Spacer()
            Text(value)
                .font(AppTypography.medium(size))
                .foregroundStyle(AppTheme.primaryText)
                .accessibilityIdentifier(accessibilityIdentifier)
                .accessibilityValue(value)
        }
    }
}
