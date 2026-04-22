import SwiftUI

struct ChevronNavigationRowLabel: View {
    let title: LocalizedStringKey
    let titleFont: Font
    let chevronFont: Font
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let minHeight: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        HStack {
            Text(title)
                .font(titleFont)
                .foregroundStyle(AppTheme.primaryText)

            Spacer(minLength: FigmaConstants.spacings.smallPadding)

            Image(systemName: "chevron.right")
                .font(chevronFont)
                .foregroundStyle(AppTheme.primaryText)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .frame(minHeight: minHeight)
        .surfaceCard(cornerRadius: cornerRadius)
    }
}
