//
//  TheCrimsonApp.swift
//  TheCrimson
//
//  Created by Noah Brauner on 2/19/26.
//

import SwiftUI

@main
struct TheCrimsonApp: App {
    var body: some Scene {
        WindowGroup {
            GeometryReader { geo in
                CrimsonRootView()
                    .environment(\.props, AppProperties(
                        size: geo.size,
                        safeAreaInsets: geo.safeAreaInsets
                    ))
            }
        }
    }
}
