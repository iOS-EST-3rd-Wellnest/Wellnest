//
//  SettingsView.swift
//  Wellnest
//
//  Created by 전광호 on 7/31/25.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = UserInfoViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    if let user = viewModel.userEntity {
                        NavigationLink {
                            ProfileDetailView(viewModel: viewModel, userEntity: user)
                        } label: {
                            ProfileView(userEntity: user)
                        }
                    }

                    SettingList()
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
