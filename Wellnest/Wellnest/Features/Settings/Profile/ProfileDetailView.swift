//
//  ProfileDetailView.swift
//  Wellnest
//
//  Created by 전광호 on 7/31/25.
//

import SwiftUI

struct ProfileDetailView: View {
    @Binding var name: String
    @State private var selectedAge: UserAgeRange? = nil
    @Binding var height: String
    @Binding var weight: String
    @State private var selectedGender: UserGender? = nil
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Form {
                HStack {
                    Spacer()
                    Circle()
                        .foregroundStyle(.indigo)
                        .frame(width: 120, height: 120)
                    Spacer()
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                
                Section {
                    HStack {
                        Text("이름")
                            .foregroundStyle(.secondary)
                            .padding(.trailing)
                        
                        TextField("이름을 입력해주세요.", text: $name)
                    }
                    
                    HStack {
                        Text("나이")
                            .foregroundStyle(.secondary)
                            .padding(.trailing)
                        
                        Menu {
                            ForEach(UserAgeRange.allCases) { group in
                                Button(group.rawValue) {
                                    selectedAge = group
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedAge?.rawValue ?? "나이를 선택해주세요.")
                                    .foregroundStyle(selectedAge == nil ? .gray.opacity(0.5) : .primary)
                                
                            }
                        }
                    }
                    
                    HStack {
                        Text("키 / 몸무게")
                            .foregroundStyle(.secondary)
                            .padding(.trailing)
                        
                        Spacer()
                        
                        HStack {
                            TextField("키", text: $height)
                                .keyboardType(.numberPad)
                                .frame(width: 50)
                            
                            Text("cm")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack {
                            TextField("몸무게", text: $weight)
                                .keyboardType(.numberPad)
                                .frame(width: 50)
                            
                            Text("kg")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    
                    HStack {
                        Text("성별")
                            .padding(.trailing)
                        
                        Menu {
                            ForEach(UserGender.allCases) { group in
                                Button(group.rawValue) {
                                    selectedGender = group
                                }
                            }
                        } label: {
                            Text(selectedGender?.rawValue ?? "성별을 선택해주세요.")
                                .foregroundStyle(selectedGender == nil ? .gray.opacity(0.5) : .primary)
                        }
                    }
                }
                
                //                Section("이름") {
                //                    TextField("이름을 입력해주세요.", text: $name)
                //                        .padding(.leading)
                //                        .listRowInsets(EdgeInsets())
                //                }
                //
                //                Section("나이") {
                //                    Menu {
                //                        ForEach(UserAgeRange.allCases) { group in
                //                            Button(group.rawValue) {
                //                                selectedAge = group
                //                            }
                //                        }
                //                    } label: {
                //                        HStack {
                //                            Text(selectedAge?.rawValue ?? "나이를 선택해주세요.")
                //                                .foregroundStyle(selectedAge == nil ? .gray.opacity(0.5) : .primary)
                //
                //                        }
                //                    }
                //                }
                //
                //                Section("키 / 몸무게") {
                //                    HStack(spacing: 16) {
                //                        HStack {
                //                            TextField("키", text: $height)
                //                                .keyboardType(.numberPad)
                //                                .frame(width: 50)
                //
                //                            Text("cm")
                //                                .foregroundStyle(.secondary)
                //                        }
                //                        .frame(maxWidth: .infinity, alignment: .leading)
                //
                //                        Spacer()
                //
                //                        HStack {
                //                            TextField("몸무게", text: $weight)
                //                                .keyboardType(.numberPad)
                //                                .frame(width: 50)
                //
                //                            Text("kg")
                //                                .foregroundStyle(.secondary)
                //                        }
                //                        .frame(maxWidth: .infinity, alignment: .trailing)
                //                    }
                //                }
                //
                //                Section("성별") {
                //                                    Menu {
                //                                        ForEach(UserGender.allCases) { group in
                //                                            Button(group.rawValue) {
                //                                                selectedGender = group
                //                                            }
                //                                        }
                //                                    } label: {
                //                                        Text(selectedGender?.rawValue ?? "성별을 선택해주세요.")
                //                                            .foregroundStyle(selectedGender == nil ? .gray.opacity(0.5) : .primary)
                //                                    }
                //                }
                .navigationTitle("프로필 수정")
                .navigationBarTitleDisplayMode(.inline)
                
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // TODO: 수정버튼 누르면 변경 항목들 저장
                        
                        dismiss()
                    } label: {
                        Text("수정")
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileDetailView(name: .constant("홍길동"), height: .constant("180"), weight: .constant("75"))
}
