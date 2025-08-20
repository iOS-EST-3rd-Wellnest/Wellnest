//
//  SettingsView.swift
//  Wellnest
//
//  Created by 전광호 on 7/31/25.
//

import SwiftUI

struct SettingsView: View {
    @State var name: String = "홍길동"
    @State private var height: String = ""
    @State private var weight: String = ""
    @State private var age: String = ""
    @State private var gender: String = ""
    @State var profileImage: UIImage?
    @Environment(\.colorScheme) var darkMode
    
    @EnvironmentObject var navBus: NavBus
    @State private var path = NavigationPath()  

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    NavigationLink {
                        ProfileDetailView(name: $name, height: $height, weight: $weight, profileImage: $profileImage)
                    } label: {
                        ProfileView(name: $name, profileImage: $profileImage)
                    }
                    
                    VStack(spacing: 24) {

                        // 섹션 1
                        VStack(alignment: .leading, spacing: Spacing.inline) {
                            Text("앱 설정")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .padding(.leading, Spacing.inline)

                            VStack(spacing: 0) {
                                NotificationView()

                                NavigationLink {
                                    HealthKitInterworkView()
                                } label: {
                                    SettingsRow(icon: "heart",
                                                title: "건강 앱 연동")
                                    .foregroundStyle(darkMode == .dark ? .white : .black)
                                }

                                NavigationLink {
                                    CalendarInterworkView()
                                } label: {
                                    SettingsRow(icon: "calendar", title: "캘린더 앱 연동")
                                        .foregroundStyle(darkMode == .dark ? .white : .black)
                                }

                                NavigationLink {
                                    CheckInMainView()
                                } label: {
                                    SettingsRow(icon: "calendar", title: "Sentiment Score")
                                        .foregroundStyle(.black)
                                }

                                NavigationLink {
                                    ResetDataView()
                                } label: {
                                    SettingsRow(icon: "trash", title: "데이터 초기화")
                                        .foregroundStyle(.red)
                                }

                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        }

                        VStack(alignment: .leading, spacing: Spacing.inline) {
                            Text("피드백")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .padding(.leading, Spacing.inline)

                            VStack(spacing: 0) {
                                NavigationLink {
                                    ModifyingSurveyView()
                                } label: {
                                    SettingsRow(icon: "ecg.text.page", title: "설문 수정")
                                        .foregroundStyle(darkMode == .dark ? .white : .black)
                                }
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        }
                    }
                    .padding()
                }
            }
            // ✅ 목적지 매핑
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .checkIn:
                    CheckInMainView()
                }
            }
            // ✅ 알림 신호 받으면 바로 push
            .onChange(of: navBus.openSettingsCheckIn) { go in
                if go {
                    // 탭 전환 직후 푸시 타이밍 안정화를 위해 아주 약간 지연
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        path.append(SettingsRoute.checkIn)
                        navBus.openSettingsCheckIn = false // 소진
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}

enum SettingsRoute: Hashable {
    case checkIn
}
