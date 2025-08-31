//
//  View+Modifier.swift
//  Wellnest
//
//  Created by 박동언 on 8/1/25.
//

import SwiftUI

struct RoundedBorderModifier: ViewModifier {
    var cornerRadius: CGFloat
    var color: Color
    var lineWidth: CGFloat
    
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

struct TabBarGlassBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    Rectangle().fill(.ultraThinMaterial)
                    Rectangle().fill(colorScheme == .light ? .white : .black)
                }
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .black.opacity(0.5), location: 0.3),
                            .init(color: .black, location: 0.5),
                            .init(color: .black, location: 1.0)
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                }
                .ignoresSafeArea(edges: .bottom)
            }
    }
}

extension View {
    func defaultShadow(
        color: Color = .black.opacity(0.05),
        radius: CGFloat = 6,
        x: CGFloat = 2,
        y: CGFloat = 2
    ) -> some View {
        self.shadow(color: color, radius: radius, x: x, y: y)
    }
    
    func roundedBorder(
        cornerRadius: CGFloat,
        color: Color = .secondary.opacity(0.5),
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
    
    func tabBarGlassBackground() -> some View {
        modifier(TabBarGlassBackgroundModifier())
    }
}
