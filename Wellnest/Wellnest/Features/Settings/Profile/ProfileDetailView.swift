//
//  ProfileDetailView.swift
//  Wellnest
//
//  Created by 전광호 on 7/31/25.
//

import SwiftUI

struct ProfileDetailView: View {
    @State private var name = ""
    @State private var age = ""
    @State private var height = ""
    @State private var weight = ""
    var body: some View {
        VStack {
            Form {
                HStack {
                    Spacer()
                    Circle()
                        .frame(width: 100, height: 100)
                        .foregroundStyle(.indigo)
                        .clipShape(Circle())
                    Spacer()
                }
                .listRowInsets(EdgeInsets())
                
                Section(header: Text("이름"), footer: EmptyView()) {
                    TextField("이름을 입력해주세요.", text: $name)
                        .padding()
                        .font(.caption)
//                        .overlay {
//                            RoundedRectangle(cornerRadius: 16)
//                                .stroke(lineWidth: 1).opacity(0.3)
//                        }
                        .listRowInsets(EdgeInsets())
                }
                
                Section("나이") {
                    
                }
                
                Section("키 / 몸무게") {
                    HStack {
                        HStack {
                            TextField("키를 입력해주세요.", text: $height)
                                .padding()
                                .font(.caption)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(lineWidth: 1).opacity(0.3)
                                }
                            
                            Text("cm")
                                
                        }
                        
                        HStack {
                            TextField("몸무게를 입력해주세요.", text: $weight)
                                .padding()
                                .font(.caption)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(lineWidth: 1).opacity(0.3)
                                }
                            
                            Text("kg")
                                
                        }
                    }
                }
            }
            .navigationTitle("프로필 수정")
            .navigationBarTitleDisplayMode(.inline)
            
            
        }
    }
}

#Preview {
    ProfileDetailView()
}
