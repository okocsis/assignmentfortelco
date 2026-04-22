import SwiftUI

struct SurfaceCardModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(AppTheme.surface)
            .clipShape(.rect(cornerRadius: cornerRadius))
    }
}

extension View {
    func surfaceCard(cornerRadius: CGFloat = AppTheme.cornerMedium) -> some View {
        modifier(SurfaceCardModifier(cornerRadius: cornerRadius))
    }
}
