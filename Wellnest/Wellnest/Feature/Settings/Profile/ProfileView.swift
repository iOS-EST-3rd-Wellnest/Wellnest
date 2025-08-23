//
//  ProfileView.swift
//  Wellnest
//
//  Created by 전광호 on 7/31/25.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var userEntity: UserEntity
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text(userEntity.nickname ?? "홍길동")
                            .foregroundStyle(.indigo)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("님")
                            .foregroundStyle(.primary)
                            .font(.title)
                            .fontWeight(.semibold)
                    }
                    
                    Text("오늘도 건강하세요!")
                        .foregroundStyle(.primary)
                        .font(.title)
                        .fontWeight(.semibold)
                }

                Spacer()

                if let data = userEntity.profileImage,
                let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                } else {
                    Image("img_profile")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                }
            }
        }
        .padding()
    }
}

//#Preview {
//    ProfileView(name: , profileImage: .constant(nil))
//}
