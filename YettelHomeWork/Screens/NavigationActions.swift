import SwiftUI

private struct PopToRootActionKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var popToRoot: () -> Void {
        get { self[PopToRootActionKey.self] }
        set { self[PopToRootActionKey.self] = newValue }
    }
}
