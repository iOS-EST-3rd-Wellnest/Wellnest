//
//  CalendarView.swift
//  Wellnest
//
//  Created by 전광호 on 8/1/25.
//

import SwiftUI

struct CalendarInterworkView: View {
    @State private var isOn = false // TODO: 추후 UserDefault로 값 저장
    
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
            
            Spacer()
            
            if isOn {
                // TODO: 연동코드 작성
            }
        }
        .padding()
        .navigationTitle("캘린더 연동")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    CalendarInterworkView()
}
