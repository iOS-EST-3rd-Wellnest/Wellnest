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
        case "wellnestaccentblue": return .wellnestAccentBlue
        case "wellnestaccentbrown": return .wellnestAccentBrown
        case "wellnestaccentgray": return .wellnestAccentGray
        case "wellnestaccentgreen": return .wellnestAccentGreen
        case "wellnestaccentpeach": return .wellnestAccentPeach
        case "wellnestaccentpink": return .wellnestAccentPink
        case "wellnestaccentpurple": return .wellnestAccentPurple
        case "wellnestaccentyellow": return .wellnestAccentYellow
        default: return .wellnestOrange
        }
    }

    static func scheduleDot(color: String) -> Color {
        return scheduleSolid(color: color)
    }
}
