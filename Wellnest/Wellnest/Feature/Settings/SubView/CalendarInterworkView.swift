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
            
            Button {
                
            } label: {
                Text("캘린더 앱 연동하기")
                    .padding(Spacing.content)
                    .frame(maxWidth: .infinity)
                    .fontWeight(.bold)
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 100)
        }
//        VStack {
//            Spacer()
//            
//            Text("캘린더앱과 연동하여 일정을 가져옵니다.")
//                .padding()
//                .overlay {
//                    RoundedRectangle(cornerRadius: CornerRadius.medium)
//                        .stroke(lineWidth: 1)
//                }
//            
//            Toggle(isOn: $isOn) {
//                Text("캘린더 연동하기")
//            }
//            .onChange(of: isOn) { newValue in
//                if newValue {
//                    handleCalendarAccess()
//                    
//                    let store = EKEventStore()
//                    store.requestAccess(to: .event) { granted, error in
//                        if let error {
//                            print("에러발생: \(error)")
//                        }
//                        
//                        if granted {
//                            print("캘린더 접근 허용")
//                        } else {
//                            print("캘린더 접근 거부")
//                        }
//                    }
//                }
//            }
//            
//            Spacer()
//            
//            if isOn {
//                // TODO: 연동코드 작성
//            }
//        }
        .padding()
        .navigationTitle("캘린더 연동")
        .navigationBarTitleDisplayMode(.inline)
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
