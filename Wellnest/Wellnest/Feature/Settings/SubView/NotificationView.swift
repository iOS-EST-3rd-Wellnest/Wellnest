//
//  NotificationView.swift
//  Wellnest
//
//  Created by 전광호 on 7/31/25.
//

import SwiftUI
import UserNotifications

struct NotificationView: View {
    @State private var showAlert: Bool = false
    @StateObject private var userDefault = UserDefaultsManager.shared
    
    var body: some View {
        Toggle(isOn: $userDefault.isNotificationEnabled) {
            ReminderRow(icon: "bell", title: "알림 설정")
        }
        .onChange(of: userDefault.isNotificationEnabled) { newValue in
            if newValue {
                LocalNotiManager.shared.requestNotificationAuthorization { granted in
                    if !granted {
                        userDefault.isNotificationEnabled = false
                        showAlert = true
                    }
                }
            }
        }
        .tint(.wellnestOrange)
        .alert("알림 권한이 꺼져있습니다.", isPresented: $showAlert) {
            Button("설정으로 이동") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            
            Button("취소", role: .cancel) { }
        } message: {
            Text("설정 > Wellnest 알림 권한을 허용해야 알림을 받을 수 있습니다.")
        }
    }
}

struct ReminderRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 28, height: 28)
            
            Text(title)
                .foregroundStyle(.primary)
            
            Spacer()
        }
        .padding(Spacing.content)
    }
}

#Preview {
    NotificationView()
}
