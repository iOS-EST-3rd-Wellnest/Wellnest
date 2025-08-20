//
//  SettingsView.swift
//  Wellnest
//
//  Created by 전광호 on 7/31/25.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = UserInfoViewModel()

    @State var name: String = "홍길동"
    @State var profileImage: UIImage?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    NavigationLink {
                        if let user = viewModel.userEntity {
                            ProfileDetailView(userEntity: user, profileImage: $profileImage)
                        }
                    } label: {
                        ProfileView(name: $name, profileImage: $profileImage)
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
