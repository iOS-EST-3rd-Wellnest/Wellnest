//
//  SettingsView.swift
//  Wellnest
//
//  Created by 전광호 on 7/31/25.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = UserInfoViewModel()

    @State private var isProfileDetailPresented = false
    @State private var currentPage: Int = 0
    @State private var isNicknameValid = true
    @State private var offsetY: CGFloat = .zero

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    SafeAreaBlurView(offsetY: $offsetY, space: .named("settingScroll"))
                    
                    if let user = viewModel.userEntity {
                        Button {
                            isProfileDetailPresented = true
                        } label: {
                            ProfileView(userEntity: user)
                        }
                    }
                    SettingList()
                }
            }
            .coordinateSpace(name: "settingScroll")
            .safeAreaBlur(offsetY: $offsetY)
            .fullScreenCover(isPresented: $isProfileDetailPresented) {
                if let user = viewModel.userEntity {
                    NavigationView {
                        ProfileDetailView(viewModel: viewModel, userEntity: user, currentPage: $currentPage, isNicknameValid: $isNicknameValid)
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
