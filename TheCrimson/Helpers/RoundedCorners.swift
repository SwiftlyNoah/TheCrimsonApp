//
//  RoundedCorners.swift
//  TheCrimson
//
//  Created by Noah Brauner on 2/19/26.
//

import SwiftUI

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    var animatableData: CGFloat {
        get { radius }
        set { radius = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: animatableData, height: animatableData))
        return Path(path.cgPath)
    }
}
