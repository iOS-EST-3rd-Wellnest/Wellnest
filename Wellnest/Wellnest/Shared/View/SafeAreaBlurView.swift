//
//  SafeAreaBlurView.swift
//  Wellnest
//
//  Created by JuYong Lee on 8/25/25.
//

import SwiftUI

private struct ScrollPreferenceKeyTmp: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}

struct SafeAreaBlurView: View {
    @Binding var offsetY: CGFloat
    
    let space: CoordinateSpace
    
    var body: some View {
        GeometryReader { proxy in
            let offsetY = proxy.frame(in: space).minY
            Color.clear
                .preference(key: ScrollPreferenceKeyTmp.self, value: offsetY)
                .onAppear {
                    self.offsetY = offsetY
                }
        }
        .frame(height: 0)
    }
}

struct SafeAreaScrollBlurModifier: ViewModifier {
    @Binding var offsetY: CGFloat
    
    func body(content: Content) -> some View {
        content
            .onPreferenceChange(ScrollPreferenceKeyTmp.self) { self.offsetY = $0 }
            .overlay(alignment: .top) {
                GeometryReader { proxy in
                    Group{
                        if offsetY >= 0 {
                            Rectangle()
                                .fill(Color(.systemBackground))
                        } else {
                            Rectangle()
                                .fill(.ultraThinMaterial)
                        }
                    }
                    .frame(height: proxy.safeAreaInsets.top)
                    .ignoresSafeArea(edges: .top)
                }
                .allowsHitTesting(false)
            }
    }
}

extension View {
    func safeAreaBlur(offsetY: Binding<CGFloat>)  -> some View {
        self.modifier(SafeAreaScrollBlurModifier(offsetY: offsetY))
    }
}

