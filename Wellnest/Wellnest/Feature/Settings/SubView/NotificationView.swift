//
//  NotificationView.swift
//  Wellnest
//
//  Created by 전광호 on 7/31/25.
//

import SwiftUI
import UserNotifications

struct NotificationView: View {
    @StateObject private var userDefault = UserDefaultsManager.shared
    
    var body: some View {
        Toggle(isOn: $userDefault.isNotificationEnabled) {
            ReminderRow(icon: "bell", title: "알림 설정")
        }
        .onChange(of: userDefault.isNotificationEnabled) { newValue in
            if newValue {
                LocalNotiManager.shared.requestNotificationAuthorization()
            }
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
