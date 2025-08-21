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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
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
            .fullScreenCover(isPresented: $isProfileDetailPresented) {
                if let user = viewModel.userEntity {
                    NavigationStack {
                        ProfileDetailView(viewModel: viewModel, userEntity: user)
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
