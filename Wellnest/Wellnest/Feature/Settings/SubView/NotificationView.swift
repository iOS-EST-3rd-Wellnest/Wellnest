//
//  NotificationView.swift
//  Wellnest
//
//  Created by 전광호 on 7/31/25.
//

import SwiftUI
import UserNotifications

struct NotificationView: View {
    @State var isOn = false
    @StateObject private var userDefault = UserDefaultsManager.shared
    
    var body: some View {
        Text("알림 설정을 해주세요.")
            .padding()
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(lineWidth: 1)
            }
        
        Toggle(isOn: $userDefault.isNotificationEnabled) {
            Text("앱 내의 알림 받기")
        }
        .onChange(of: userDefault.isNotificationEnabled) { newValue in
            if newValue {
                LocalNotiManager.shared.requestNotificationAuthorization()
            }
        }
    }
}

#Preview {
    NotificationView()
}
