//
//  CalendarView.swift
//  Wellnest
//
//  Created by 전광호 on 8/1/25.
//

import SwiftUI
import EventKit

struct CalendarInterworkView: View {
    @State private var isOn: Bool = false // TODO: 추후 UserDefault로 값 저장
    @State private var showSettingAlert: Bool = false
    
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("캘린더앱과 연동하여 일정을 가져옵니다.")
                .padding()
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                        .stroke(lineWidth: 1)
                }
            
            Toggle(isOn: $isOn) {
                Text("캘린더 연동하기")
            }
            .onChange(of: isOn) { newValue in
                if newValue {
                    handleCalendarAccess()
                    
                    let store = EKEventStore()
                    store.requestAccess(to: .event) { granted, error in
                        if let error {
                            print("에러발생: \(error)")
                        }
                        
                        if granted {
                            print("캘린더 접근 허용")
                        } else {
                            print("캘린더 접근 거부")
                        }
                    }
                }
            }
            
            Spacer()
            
            if isOn {
                // TODO: 연동코드 작성
            }
        }
        .padding()
        .navigationTitle("캘린더 연동")
        .navigationBarTitleDisplayMode(.inline)
        .alert("캘린더 접근이 필요합니다.", isPresented: $showSettingAlert) {
            Button("설정으로 이동") {
                if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            }
            
            Button("취소", role: .cancel) {
                isOn = false
            }
        } message: {
            Text("설정에서 캘린더 앱의 접근을 허용해주세요.")
        }
    }
    
    func handleCalendarAccess() {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .notDetermined:
            print("접근이 요청되지 않음")
        case .denied, .restricted:
            print("사용자가 접근 거부")
            showSettingAlert = true
        case .authorized:
            print("접근 허용")
        @unknown default:
            break
        }
    }
}

#Preview {
    CalendarInterworkView()
}
