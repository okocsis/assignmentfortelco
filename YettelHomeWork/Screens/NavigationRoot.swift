import SwiftUI

struct NavigationRoot: View {
    let dependencies: AppDependencies

    var body: some View {
        NavigationStack {
            VignetteHomeScreen(dependencies: dependencies)
        }
    }
}
