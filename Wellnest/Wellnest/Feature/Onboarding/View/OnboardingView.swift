//
//  OnboardingView.swift
//  Wellnest
//
//  Created by 정소이 on 8/1/25.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("isOnboarding") var isOnboarding: Bool = false // TODO: 문자열 말고 속성으로 하기

    var body: some View {
        // Home
        if isOnboarding {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Text("Hello, world!")
            }
            .padding()
        }

        // Onboarding
        else {
            OnboardingTabView()
        }
    }
}

#Preview {
    OnboardingView()
        .onAppear {
            UserDefaults.standard.set(false, forKey: "isOnboarding")
        }
}
