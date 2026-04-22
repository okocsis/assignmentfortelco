import SwiftUI

struct EVignetteNavigationBarModifier: ViewModifier {
    let title: LocalizedStringKey

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.accentLime, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}

extension View {
    func eVignetteNavigationBar(title: LocalizedStringKey = "common.title.e_vignette") -> some View {
        modifier(EVignetteNavigationBarModifier(title: title))
    }
}
