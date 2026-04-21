//
//  YettelHomeWorkApp.swift
//  YettelHomeWork
//
//  Created by Olivér Kocsis on 2026. 04. 17..
//

import SwiftUI

@main
struct YettelHomeWorkApp: App {
    private let dependencies = AppDependencies.live

    var body: some Scene {
        WindowGroup {
            ContentView(dependencies: dependencies)
                .environment(\.appDependencies, dependencies)
        }
    }
}
