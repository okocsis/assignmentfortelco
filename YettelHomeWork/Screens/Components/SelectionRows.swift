import SwiftUI

struct SelectablePriceRow<Leading: View>: View {
    let title: String
    let value: String
    let titleFont: Font
    let valueFont: Font
    let titleColor: Color
    let valueColor: Color
    let spacing: CGFloat
    let spacerMinLength: CGFloat
    let verticalPadding: CGFloat
    let minHeight: CGFloat
    let action: () -> Void
    @ViewBuilder let leading: () -> Leading

    var body: some View {
        Button(action: action) {
            HStack(spacing: spacing) {
                leading()

                Text(title)
                    .font(titleFont)
                    .foregroundStyle(titleColor)

                Spacer(minLength: spacerMinLength)

                Text(value)
                    .font(valueFont)
                    .foregroundStyle(valueColor)
            }
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
            .padding(.vertical, verticalPadding)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
