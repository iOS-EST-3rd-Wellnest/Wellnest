//
//  TestAIInputView.swift
//  Wellnest
//
//  Created by 박동언 on 8/4/25.
//

import SwiftUI

struct TestAIInputView: View {
    @Binding var selectedTab: TabBarItem
    @Binding var selectedCreationType: ScheduleCreationType?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                Text("AI가 일정을 생성합니다.")

                Button("완료") {
                    selectedCreationType = nil
                    selectedTab = .plan
                    dismiss()
                }
            }
            .navigationTitle("AI 일정 생성")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        selectedCreationType = nil
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TestAIInputView(selectedTab: .constant(.plan), selectedCreationType: .constant(nil))
}
