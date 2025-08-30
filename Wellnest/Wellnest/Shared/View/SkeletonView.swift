//
//  SkeletonView.swift
//  Wellnest
//
//  Created by JuYong Lee on 8/24/25.
//

import SwiftUI

struct SkeletonView<S: Shape>: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAnimating = false
    
    var shape: S
    
    var animation: Animation {
        .easeIn(duration: 1.5).repeatForever(autoreverses: false)
    }

    var body: some View {
        shape
            .fill(.wellnestBackgroundCard)
            .overlay {
                GeometryReader {
                    let size = $0.size
                    let animationRectWidth = size.width / 2
                    let blurRadius = max(animationRectWidth / 2, 30)
                    
                    let minX = -size.width
                    let maxX = size.width * 2

                    Rectangle()
                        .fill(colorScheme == .dark ? Color(.lightGray).opacity(0.5) : .gray.opacity(0.5))
                        .frame(width: animationRectWidth / 4, height: size.height * 2)
                        .frame(height: size.height)
                        .rotationEffect(.init(degrees: 5))
                        .blur(radius: blurRadius)
                        .blendMode(colorScheme == .dark ? .hardLight : .darken)
                        .offset(x: isAnimating ? maxX : minX)
                }
            }
            .clipShape(shape)
            .compositingGroup()
            .onAppear {
                guard !isAnimating else { return }
                withAnimation(animation) {
                    isAnimating = true
                }
            }
            .onDisappear {
                isAnimating = false
            }
    }
}

#Preview {
    SkeletonView(shape: .rect)
        .frame(width: 200, height: 200)
}
