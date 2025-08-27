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
        case "red": return .red.opacity(0.3)
        case "blue": return .blue.opacity(0.3)
        case "green": return .green.opacity(0.3)
        case "yellow": return .yellow.opacity(0.3)
        case "orange": return .orange.opacity(0.3)
        case "purple": return .purple.opacity(0.3)
        case "pink": return .pink.opacity(0.3)
        case "gray": return .gray.opacity(0.3)
        case "wellnestblue": return .wellnestBlue
        case "wellnestbrown": return .wellnestBrown
        case "wellnestgray": return .wellnestGray
        case "wellnestgreen": return .wellnestGreen
        case "wellnestpeach": return .wellnestPeach
        case "wellnestpink": return .wellnestPink
        case "wellnestpurple": return .wellnestPurple
        case "wellnestyellow": return .wellnestYellow
        default: return .blue
        }
    }

    static func scheduleSolid(color: String) -> Color {
        switch color.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "gray": return .gray
        case "wellnestblue": return .wellnestAccentBlue
        case "wellnestbrown": return .wellnestAccentBrown
        case "wellnestgray": return .wellnestAccentGray
        case "wellnestgreen": return .wellnestAccentGreen
        case "wellnestpeach": return .wellnestAccentPeach
        case "wellnestpink": return .wellnestAccentPink
        case "wellnestpurple": return .wellnestAccentPurple
        case "wellnestyellow": return .wellnestAccentYellow
        default: return .purple
        }
    }

    static func scheduleDot(color: String) -> Color {
        return scheduleSolid(color: color)
    }
}
