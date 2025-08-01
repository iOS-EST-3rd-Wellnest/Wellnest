//
//  ProfileView.swift
//  Wellnest
//
//  Created by 전광호 on 7/31/25.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        HStack {
            Circle()
                .frame(width: 40, height: 40)
                .foregroundStyle(.indigo)
                
            VStack {
                Text("이름")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text("E-mail")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
            
            Spacer()
            
            Image(systemName: "pencil.line")
                .font(.title2)
        }
    }
}

#Preview {
    ProfileView()
}
