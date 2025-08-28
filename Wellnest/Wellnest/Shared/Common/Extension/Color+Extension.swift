//
//  Color+Extension.swift
//  Wellnest
//
//  Created by 박동언 on 8/13/25.
//

import SwiftUI

extension Color {

    static func scheduleBackground(color: String) -> Color {
        switch color.lowercased() {
        case "wellnestblue": return .wellnestBlue
        case "wellnestbrown": return .wellnestBrown
        case "wellnestgray": return .wellnestGray
        case "wellnestgreen": return .wellnestGreen
        case "wellnestpeach": return .wellnestPeach
        case "wellnestpink": return .wellnestPink
        case "wellnestpurple": return .wellnestPurple
        case "wellnestyellow": return .wellnestYellow
        default: return .wellnestPeach
        }
    }

    static func scheduleSolid(color: String) -> Color {
        switch color.lowercased() {
        case "wellnestblue": return .wellnestAccentBlue
        case "wellnestbrown": return .wellnestAccentBrown
        case "wellnestgray": return .wellnestAccentGray
        case "wellnestgreen": return .wellnestAccentGreen
        case "wellnestpeach": return .wellnestAccentPeach
        case "wellnestpink": return .wellnestAccentPink
        case "wellnestpurple": return .wellnestAccentPurple
        case "wellnestyellow": return .wellnestAccentYellow
        default: return .wellnestOrange
        }
    }

    static func scheduleDot(color: String) -> Color {
        return scheduleSolid(color: color)
    }
}
