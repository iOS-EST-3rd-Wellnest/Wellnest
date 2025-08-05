//
//  SettingsView.swift
//  Wellnest
//
//  Created by 전광호 on 7/31/25.
//

import SwiftUI

struct SettingsView: View {
    @State var name: String = "홍길동"
    @State private var height: String = "185"
    @State private var weight: String = "80"
    @State var profileImage: UIImage? = nil
    
    var body: some View {
        NavigationStack {
            List {
                /// 프로필 navigation 방식
                NavigationLink {
                    ProfileDetailView(name: $name, height: $height, weight: $weight, profileImage: $profileImage)
                } label: {
                    ProfileView(name: $name, profileImage: $profileImage)
                }
                
                Section(header: Text("앱 설정")) {
                    // TODO: 알림
                    NavigationLink {
                        NotificationView()
                    } label: {
                        Label("알림 설정", systemImage: "bell")
                            .foregroundStyle(.primary)
                        
                    }
                    
                    // TODO: 캘린더 연동
                    NavigationLink {
                        CalendarInterworkView()
                    } label: {
                        Label("캘린더 연동", systemImage: "calendar")
                            .foregroundStyle(.primary)
                    }
                    
                    // TODO: 헬스킷 연동
                    NavigationLink {
                        HealthKitInterworkView()
                    } label: {
                        Label("헬스킷 연동", systemImage: "heart")
                            .foregroundStyle(.primary)
                    }
                    
                    // TODO: 데이터 초기화 설정
                    NavigationLink {
                        ResetDataView()
                    } label: {
                        Label("데이터 초기화", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                }
                
                Section(header: Text("피드백")) {
                    // TODO: 설문 수정
                    NavigationLink {
                        ModifyingSurveyView()
                    } label: {
                        Label("설문 수정", systemImage: "ecg.text.page")
                            .foregroundStyle(.primary)
                    }
                }
            }
            .navigationTitle("설정")
            .listStyle(.insetGrouped)
        }
    }
}

#Preview {
    SettingsView()
}
