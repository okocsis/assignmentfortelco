import SwiftUI

struct RadioSelectionIndicator: View {
    let isSelected: Bool
    let outerSize: CGFloat
    let innerSize: CGFloat
    let borderWidth: CGFloat
    let unselectedBorderColor: Color
    let selectedFillColor: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(unselectedBorderColor, lineWidth: borderWidth)
                .frame(width: outerSize, height: outerSize)

            if isSelected {
                Circle()
                    .fill(selectedFillColor)
                    .frame(width: innerSize, height: innerSize)
            }
        }
    }
}

struct CheckboxSelectionIndicator: View {
    let isSelected: Bool
    let size: CGFloat
    let selectedColor: Color
    let unselectedColor: Color

    var body: some View {
        Image(systemName: isSelected ? "checkmark.square.fill" : "square")
            .font(AppTypography.medium(size))
            .foregroundStyle(isSelected ? selectedColor : unselectedColor)
    }
}
