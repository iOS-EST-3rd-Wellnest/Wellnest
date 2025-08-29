//
//  SplashView.swift
//  Wellnest
//
//  Created by 정소이 on 8/29/25.
//

import SwiftUI

struct SplashView: View {
    @State private var opacity = 0.0

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1.0, green: 0.40, blue: 0.08),
                    Color(red: 1.0, green: 0.70, blue: 0.28)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack {
                Image("splashImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
            }
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 0.9)) {
                    opacity = 1.0
                }
            }
        }
    }
}

#Preview {
    SplashView()
}
