//
//  WellnestApp.swift
//  Wellnest
//
//  Created by Heejung Yang on 7/31/25.
//

import SwiftUI
import Firebase

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
//        LocalNotiManager.shared.localNotiDelegate()
        return true
    }
}

@main
struct WellnestApp: App {
    @StateObject private var navBus = NavBus()

    init() {
        // 🔑 알림 델리게이트 "아주 이르게" 연결 (알림 탭 이벤트 받기 위함)
        LocalNotiManager.shared.localNotiDelegate()
        LocalNotiManager.shared.ensureMorningCheckInScheduled()
    }

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environmentObject(navBus)
                // 딥링크로 들어온 경우
                .onOpenURL { url in
                    if url.scheme == "wellnest",
                       url.host == "settings",
                       url.path == "/checkin" {
                        navBus.triggerSettingsCheckIn()
                    }
                }
                // 포그라운드에서 알림 탭(내부 노티)인 경우
                .onReceive(NotificationCenter.default.publisher(for: .openSettingsCheckIn)) { _ in
                    navBus.triggerSettingsCheckIn()
                }
        }
    }
}
