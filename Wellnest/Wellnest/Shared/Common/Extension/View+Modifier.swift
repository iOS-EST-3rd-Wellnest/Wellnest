//
//  View+Modifier.swift
//  Wellnest
//
//  Created by 박동언 on 8/1/25.
//

import SwiftUI

struct RoundedBorderModifier: ViewModifier {
    var cornerRadius: CGFloat
    var color: Color = .secondary.opacity(0.2)
    var lineWidth: CGFloat = 0.5

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(color, lineWidth: lineWidth)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

struct LayoutWidthModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(width: UIDevice.current.userInterfaceIdiom == .pad ? 600 : nil)
    }
}

extension View {
    func defaultShadow() -> some View {
        self.shadow(color: .secondary.opacity(0.2), radius: 8, x: 6, y: 6)
    }

    func roundedBorder(
        cornerRadius: CGFloat,
        color: Color = .secondary.opacity(0.6),
        lineWidth: CGFloat = 0.2
    ) -> some View {
        self.modifier(RoundedBorderModifier(
            cornerRadius: cornerRadius,
            color: color,
            lineWidth: lineWidth
        ))
    }

    func layoutWidth() -> some View {
        self.modifier(LayoutWidthModifier())
    }
}
