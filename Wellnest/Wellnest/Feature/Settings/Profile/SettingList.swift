//
//  SettingList.swift
//  Wellnest
//
//  Created by 전광호 on 8/8/25.
//

import SwiftUI

//struct SettingList: View {
//    @State private var isNotificationOn = false
//    @State private var showNotificationSettings = false
//    @State private var showHealthLink = false
//    
//    var body: some View {
//        NavigationStack {
//            List {
//                Section("설정 관리") {
//                    // 알림 설정 (토글로 바로 처리하거나, 상세 화면으로 이동)
//                    NavigationLink("알림 설정") {
//                        NotificationView()   // 이미 있는 알림 설정 화면 연결
//                    }
//                    .listRowSeparator(.visible)
//                    .labelStyle(.titleOnly)
//                    .overlay(
//                        SettingsRow(icon: "bell.fill", title: "알림 설정") { }
//                            .allowsHitTesting(false) // 외형만 내가 그리게
//                    )
//                    
//                    NavigationLink {
//                        HealthKitInterworkView() // 건강데이터/기기 연동 화면
//                    } label: {
//                        SettingsRow(icon: "arrow.triangle.2.circlepath", title: "건강데이터 및 기기 연동")
//                    }
//                }
//            }
//            .listStyle(.insetGrouped)
//            .navigationTitle("설정")
//        }
//    }
//}
    
    //    var body: some View {
    //        ScrollView {
    //            VStack(alignment: .leading) {
    //                Text("앱 설정")
    //                    .font(.title3)
    //                    .fontWeight(.bold)
    //
    //                VStack {
    //
    //                }
    //            }
    //        }
    //    }

/// 설정 셀
struct SettingsRow: View {
    let icon: String
    let title: String
    var accessory: String? = "chevron.right"   // 필요 없으면 nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 28, height: 28)
                    .foregroundStyle(.primary)
                    .background(.gray.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Text(title)
                    .foregroundStyle(.primary)

                Spacer()

                if let accessory {
                    Image(systemName: accessory)
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
            }
            .contentShape(Rectangle())
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
        }
        .buttonStyle(.plain)
    }
}

struct SettingsGroup<Content: View>: View {
    let header: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(header)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)

            VStack(spacing: 0) {
                content
                    .overlay(alignment: .bottom) { Divider().offset(x: 21) } // 각 Row 하단 라인(아이콘 영역만큼 들여쓰기)
            }
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.quaternary, lineWidth: 1)
            )
        }
    }
}

struct SettingsScreen: View {
    @State private var pushNotification = false
    @State private var pushAccount = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    SettingsGroup(header: "설정 관리") {
                        // 알림 설정
                        SettingsRow(icon: "bell.fill", title: "알림 설정") {
                            pushNotification = true
                        }
                        // 커스텀 구분선용 빈 오버레이 제거
                        .overlay(Divider().opacity(0), alignment: .bottom)

                        SettingsRow(icon: "arrow.triangle.2.circlepath", title: "건강데이터 및 기기 연동") {
                            // 네비게이션/시트/링크 등 원하는 액션
                        }
                        .overlay(Divider().opacity(0), alignment: .bottom)
                    }
                }
                .padding(16)
            }
            .navigationTitle("설정")
            // 네비게이션 전환 (List 없이도 OK)
            .background(
                NavigationLink("", isActive: $pushNotification) { NotificationView() }.hidden()
            )
        }
    }
}


#Preview {
    SettingsScreen()
}
