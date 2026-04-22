import SwiftUI

struct NavigationRoot: View {
    let dependencies: AppDependencies
    @State private var navigationRootID = UUID()

    var body: some View {
        NavigationStack {
            VignetteHomeScreen(dependencies: dependencies)
        }
        .id(navigationRootID)
        .environment(\.popToRoot) {
            navigationRootID = UUID()
        }
    }
}
