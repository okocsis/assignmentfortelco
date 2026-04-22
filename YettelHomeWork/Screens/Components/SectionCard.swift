import SwiftUI

struct SectionCard<Content: View>: View {
    let alignment: HorizontalAlignment
    let spacing: CGFloat
    let padding: CGFloat
    let cornerRadius: CGFloat
    @ViewBuilder let content: Content

    init(
        alignment: HorizontalAlignment = .leading,
        spacing: CGFloat = 0,
        padding: CGFloat = FigmaConstants.spacings.mediumPadding,
        cornerRadius: CGFloat = AppTheme.cornerMedium,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            content
        }
        .padding(padding)
        .surfaceCard(cornerRadius: cornerRadius)
    }
}
