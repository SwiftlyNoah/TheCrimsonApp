//
//  Font+Crimson.swift
//  TheCrimson
//
//  Created by Noah Brauner on 2/19/26.
//

import SwiftUI

extension Font {
    static func georgia(_ size: CGFloat, weight: Weight = .regular) -> Font {
        switch weight {
        case .bold:
            return .custom("Georgia-Bold", size: size)
        case .semibold:
            return .custom("Georgia-Bold", size: size)
        default:
            return .custom("Georgia", size: size)
        }
    }

    static func georgiaBoldItalic(_ size: CGFloat) -> Font {
        .custom("Georgia-BoldItalic", size: size)
    }

    static func georgiaItalic(_ size: CGFloat) -> Font {
        .custom("Georgia-Italic", size: size)
    }

    static let crimsonBody = Font.georgia(18)
    static let crimsonTitle = Font.georgia(28, weight: .bold)
    static let crimsonSubhead = Font.georgia(14, weight: .semibold)
    static let crimsonCaption = Font.georgia(12)
    static let crimsonQuote = Font.georgiaBoldItalic(22)
    static let crimsonLogo = Font.georgia(70, weight: .bold)
}
