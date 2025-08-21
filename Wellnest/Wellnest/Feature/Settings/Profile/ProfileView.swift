//
//  ProfileView.swift
//  Wellnest
//
//  Created by 전광호 on 7/31/25.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var userEntity: UserEntity
//    @Binding var profileImage: UIImage?
    
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
                    Circle()
                        .frame(width: 80, height: 80)
                        .foregroundStyle(.gray)
                }
            }
        }
        .padding()
//        HStack {
//            if let image = profileImage {
//                Image(uiImage: image)
//                    .resizable()
//                    .scaledToFill()
//                    .frame(width: 40, height: 40)
//                    .clipShape(Circle())
//            } else {
//                Circle()
//                    .frame(width: 40, height: 40)
//                    .foregroundStyle(.gray)
//            }
//            
//            //            Circle()
//            //                .frame(width: 40, height: 40)
//            //                .foregroundStyle(.indigo)
//            
//            Text(name)
//                .font(.title3)
//                .fontWeight(.bold)
//            
//            Spacer()
//            
//            Image(systemName: "pencil.line")
//                .font(.title2)
//        }
    }
}

//#Preview {
//    ProfileView(name: , profileImage: .constant(nil))
//}
