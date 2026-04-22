import SwiftUI

private struct LimeNavigationBarShapeStyle: ShapeStyle {
    func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
        let topOpacity: CGFloat = environment.colorSchemeContrast == .increased ? 0.96 : 0.9
        let bottomOpacity: CGFloat = environment.colorSchemeContrast == .increased ? 0.9 : 0.82

        return LinearGradient(
            colors: [
                AppTheme.accentLime.opacity(topOpacity),
                AppTheme.accentLime.opacity(bottomOpacity),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

struct EVignetteNavigationBarModifier: ViewModifier {
    let title: LocalizedStringKey

    private enum NavigationChromeMetrics {
        static let extensionHeight: CGFloat = 20
        static let bottomCornerRadius: CGFloat = 20
        static let dividerOpacity: CGFloat = 0.12
        static let shadowOpacity: CGFloat = 0.08
        static let shadowRadius: CGFloat = 8
        static let shadowY: CGFloat = 2
    }

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(LimeNavigationBarShapeStyle(), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .tint(AppTheme.primaryText)
            .overlay(alignment: .top) {
                navBarBottomExtension.allowsHitTesting(false)
            }
    }

    private var navBarBottomExtension: some View {
        Rectangle()
        .fill(LimeNavigationBarShapeStyle())
        .clipShape(
            UnevenRoundedRectangle(
                cornerRadii: .init(
                    topLeading: 0,
                    bottomLeading: NavigationChromeMetrics.bottomCornerRadius,
                    bottomTrailing: NavigationChromeMetrics.bottomCornerRadius,
                    topTrailing: 0
                ),
                style: .continuous
            )
        )
        .frame(height: NavigationChromeMetrics.extensionHeight)
    }
}

extension View {
    func eVignetteNavigationBar(title: LocalizedStringKey = "common.title.e_vignette") -> some View {
        modifier(EVignetteNavigationBarModifier(title: title))
    }
}
