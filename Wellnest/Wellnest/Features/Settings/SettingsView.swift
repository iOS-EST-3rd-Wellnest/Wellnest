//
//  SettingsView.swift
//  Wellnest
//
//  Created by 전광호 on 7/31/25.
//

import SwiftUI

struct SettingsView: View {
    @State private var showProfileSheet = false
    var body: some View {
        NavigationStack {
            List {
                /// 프로필 navigation 방식
                NavigationLink {
                    ProfileDetailView()
                } label: {
                    ProfileView()
                }
                
                Section(header: Text("앱 설정")) {
                    // TODO: 알림
                    Text("알림 설정")
                    
                    // TODO: 캘린더 연동
                    // 캘린더 연동 -> 커스텀 캘린더를 사용하는게 아닌가?
                    Text("캘린더 연동")
                    
                    // TODO: 헬스킷 동기화
                    Text("헬스킷 동기화")
                    
                    // TODO: 앱 테마 위젯 설정
                    Text("앱 테마 위젯 설정")
                }
                
                Section(header: Text("피드백")) {
                    // TODO: 설문 수정
                    Text("설문 수정")
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
