//
//  CalendarView.swift
//  Wellnest
//
//  Created by 전광호 on 8/1/25.
//

import SwiftUI
import EventKit

struct CalendarInterworkView: View {
    @StateObject private var userDefault = UserDefaultsManager.shared
    
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var showSettingAlert: Bool = false
    @State private var isAuthorizing: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 40) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.blue)
                        .font(.system(size: 40))
                    
                    VStack(alignment: .leading) {
                        Text("당신의 하루를 한눈에")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text("캘란더를 연동하면 일정과 목표를 함께 관리할 수 있습니다.")
                            .font(.footnote)
                    }
                }
                
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(.blue)
                        .font(.system(size: 40))
                    
                    VStack(alignment: .leading) {
                        Text("계획부터 실행까지")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text("캘린더를 연동하여 오늘 할 일과 건강 목표를 함께 체크하세요.")
                            .font(.footnote)
                    }
                }
            }
            
            Spacer()
            
            FilledButton(title: isAuthorizing ? "연동중..." : (userDefault.isCalendarEnabled ? "캘린더 앱 연동 됨" : "캘린더 앱 연동하기"), action: {
                Task {
                    await linkCalendar()
                }
            }, backgroundColor: userDefault.isCalendarEnabled ? .gray : .blue)
            .disabled(userDefault.isCalendarEnabled)
        }
        .padding()
        .navigationTitle("캘린더 앱 연동")
        .navigationBarTitleDisplayMode(.inline)
        .padding(.bottom, 100)
        .task {
            await refreshCalendarLinkState()
        }
        .onChange(of: scenePhase) { newValue in
            if newValue == .active {
                Task { await refreshCalendarLinkState() }
            }
        }
        .alert("설정에서 캘린더 권한이 필요합니다.", isPresented: $showSettingAlert) {
            Button("설정으로 가기") { goToSetting() }
            Button("취소", role: .cancel) {}
        }
    }
}

extension CalendarInterworkView {
    /// 현재 권한 상태를 읽어 연동 여부 플래그 갱신
    func refreshCalendarLinkState() async {
        let status = CalendarManager.shared.authorizationStatus()
        if #available(iOS 17.0, *) {
            userDefault.isCalendarEnabled = (status == .fullAccess)
        } else {
            userDefault.isCalendarEnabled = (status == .authorized)
        }
    }
    
    /// 권한 요청
    func linkCalendar() async {
        guard !userDefault.isCalendarEnabled else { return }
        isAuthorizing = true
        defer { isAuthorizing = false }
        do {
            try await CalendarManager.shared.ensureAccess()
            await refreshCalendarLinkState()
        } catch {
            showSettingAlert = true
        }
    }
    
    func goToSetting() {
        let urlString = UIApplication.openSettingsURLString
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    CalendarInterworkView()
}
