//
//  SettingsView.swift
//  Wellnest
//
//  Created by 전광호 on 7/31/25.
//

import SwiftUI

struct SettingsView: View {
    @State var name: String = "홍길동"
    @State private var height: String = ""
    @State private var weight: String = ""
    @State private var age: String = ""
    @State private var gender: String = ""
    @State var profileImage: UIImage?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    NavigationLink {
                        ProfileDetailView(name: $name, height: $height, weight: $weight, profileImage: $profileImage)
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
