//
//  AppProperties.swift
//  TheCrimson
//
//  Created by Noah Brauner on 2/19/26.
//

import SwiftUI

struct AppProperties {
    var size: CGSize = .zero
    var width: CGFloat { size.width }
    var height: CGFloat { size.height }

    var hasNotch: Bool {
        return (safeAreaInsets?.top ?? 0) > 20
    }

    var safeAreaInsets: EdgeInsets?

    var safeAreaTop: CGFloat {
        return safeAreaInsets?.top ?? 0
    }

    var safeAreaBottom: CGFloat {
        return safeAreaInsets?.bottom ?? 0
    }
}

private struct AppPropertiesKey: EnvironmentKey {
    static let defaultValue = AppProperties()
}

extension EnvironmentValues {
    var props: AppProperties {
        get { self[AppPropertiesKey.self] }
        set { self[AppPropertiesKey.self] = newValue }
    }
}
