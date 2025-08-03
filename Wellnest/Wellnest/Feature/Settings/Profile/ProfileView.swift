//
//  ProfileView.swift
//  Wellnest
//
//  Created by 전광호 on 7/31/25.
//

import SwiftUI

struct ProfileView: View {
    @Binding var name: String
    
    var body: some View {
        HStack {
            Circle()
                .frame(width: 40, height: 40)
                .foregroundStyle(.indigo)
            
            Text(name)
                .font(.title3)
                .fontWeight(.bold)
            
            Spacer()
            
            Image(systemName: "pencil.line")
                .font(.title2)
        }
    }
}

#Preview {
    ProfileView(name: .constant("홍길동"))
}
