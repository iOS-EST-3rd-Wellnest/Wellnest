//
//  SettingsView.swift
//  Wellnest
//
//  Created by 전광호 on 7/31/25.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = UserInfoViewModel()
    @EnvironmentObject private var ui: AppUIState

    @State private var isProfileDetailPresented = false
    @State private var currentPage: Int = 0

    @Environment(\.dismiss) var dismiss

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
                    NavigationView {
                        ProfileDetailView(viewModel: viewModel, userEntity: user, currentPage: $currentPage)
                    }
                }
            }
        }
    }
}

final class AppUIState: ObservableObject {
    @Published var isTabBarHidden: Bool = false
}

#Preview {
    SettingsView()
}
