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
        default: return .gray.opacity(0.3)
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
        case "accentbuttoncolor": return Color("accentButtonColor")
        case "accentcardbluecolor": return Color("accentCardBlueColor")
        case "accentcardgreencolor": return Color("accentCardGreenColor")
        case "accentcardpinkcolor": return Color("accentCardPinkColor")
        case "accentcardgreencolor": return Color("accentCardGreenColor")
        case "accentcardyellowcolor": return Color("accentCardYellowColor")
        case "backgroudcolor": return Color("backgroudColor")
        case "customsecondarycolor": return Color("CustomSecondaryColor")
        case "customgraycolor": return Color("CustomGrayColor")
        default: return .blue
        }
    }

    static func scheduleDot(color: String) -> Color {
        return scheduleSolid(color: color)
    }
}
