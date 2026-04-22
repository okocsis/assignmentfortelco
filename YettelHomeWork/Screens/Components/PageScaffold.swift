import SwiftUI

struct ScrollPageScaffold<Content: View>: View {
    let spacing: CGFloat
    let horizontalPadding: CGFloat
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    let alignment: HorizontalAlignment
    let backgroundColor: Color
    @ViewBuilder let content: () -> Content
    
    init(
        spacing: CGFloat,
        horizontalPadding: CGFloat,
        topPadding: CGFloat,
        bottomPadding: CGFloat,
        alignment: HorizontalAlignment,
        backgroundColor: Color = AppTheme.pageBackground,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.spacing = spacing
        self.horizontalPadding = horizontalPadding
        self.topPadding = topPadding
        self.bottomPadding = bottomPadding
        self.alignment = alignment
        self.backgroundColor = backgroundColor
        self.content = content
    }

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            ScrollView {
                VStack(alignment: alignment, spacing: spacing) {
                    content()
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, topPadding)
                .padding(.bottom, bottomPadding)
            }
        }
    }
}
