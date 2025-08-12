//
//  SettingList.swift
//  Wellnest
//
//  Created by 전광호 on 8/8/25.
//

import SwiftUI

/// 설정 리스트
struct SettingList: View {
    @Environment(\.colorScheme) var darkMode
    
    var body: some View {
        ScrollView {
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
}

/// 재사용 셀
struct SettingsRow: View {
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
            
            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .padding(Spacing.content)
    }
}





#Preview {
    SettingList()
}
