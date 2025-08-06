//
//  AIScheduleResultView.swift
//  Wellnest
//
//  Created by junil on 8/4/25.
//

import SwiftUI

struct AIScheduleResultView: View {
    let healthPlan: HealthPlanResponse?
    let isLoading: Bool
    let errorMessage: String
    let rawResponse: String

    @Environment(\.dismiss) private var dismiss
    @State private var showRawResponse = false

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    LoadingView()
                } else if !errorMessage.isEmpty {
                    ErrorView(errorMessage: errorMessage, rawResponse: rawResponse)
                } else if let plan = healthPlan {
                    PlanContentView(plan: plan)
                } else {
                    EmptyPlanView()
                }
            }
            .navigationTitle("생성된 플랜")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !errorMessage.isEmpty && !rawResponse.isEmpty {
                        Button("원본 응답") {
                            showRawResponse = true
                        }
                        .font(.caption)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showRawResponse) {
                RawResponseView(rawResponse: rawResponse)
            }
        }
    }
}

#Preview {
    AIScheduleResultView(
        healthPlan: HealthPlanResponse(
            planType: "routine",
            title: "주 3회 헬스 루틴",
            description: "근력 증진을 위한 체계적인 운동 계획입니다.",
            schedules: [
                AIScheduleItem(
                    day: "월요일",
                    date: nil,
                    time: "09:00 - 10:00",
                    activity: "상체 근력 운동",
                    notes: "벤치프레스, 덤벨 플라이 위주로 진행"
                )
            ]
        ),
        isLoading: false,
        errorMessage: "",
        rawResponse: ""
    )
}
