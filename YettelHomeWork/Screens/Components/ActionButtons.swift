import SwiftUI

enum ActionButtonMetrics {
    static let labelSize: CGFloat = FigmaConstants.typography.buttonLabelSize
    static let verticalPadding: CGFloat = FigmaConstants.spacings.mediumSmallPadding
    static let borderWidth: CGFloat = FigmaConstants.controls.borderWidth
}

struct PrimaryActionButtonLabel: View {
    let title: LocalizedStringKey
    var isEnabled: Bool = true

    var body: some View {
        Group {
            Text(title)
                .font(AppTypography.bold(ActionButtonMetrics.labelSize))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, ActionButtonMetrics.verticalPadding)
                .background(isEnabled ? AppTheme.primaryButton : AppTheme.primaryButton.opacity(FigmaConstants.opacity.disabled))
                .clipShape(.capsule)
        }
    }
}

struct PrimaryActionButton: View {
    let title: LocalizedStringKey
    var isEnabled: Bool = true
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ActionButtonMetrics.verticalPadding)
                    .background(AppTheme.primaryButton)
                    .clipShape(.capsule)
            } else {
                PrimaryActionButtonLabel(title: title, isEnabled: isEnabled)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
    }
}

struct SecondaryActionButton: View {
    let title: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.bold(ActionButtonMetrics.labelSize))
                .foregroundStyle(AppTheme.primaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, ActionButtonMetrics.verticalPadding)
                .overlay(
                    Capsule()
                        .stroke(AppTheme.primaryButton, lineWidth: ActionButtonMetrics.borderWidth)
                )
        }
        .buttonStyle(.plain)
    }
}
