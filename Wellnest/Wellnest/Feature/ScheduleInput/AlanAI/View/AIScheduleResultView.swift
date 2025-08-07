//
//  AIScheduleResultView.swift
//  Wellnest
//
//  Created by junil on 8/4/25.
//

import SwiftUI

struct AIScheduleResultView: View {
    @StateObject var viewModel: AIScheduleResultViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Group {
                switch viewModel.currentViewState {
                case .loading:
                    LoadingView()
                case .error:
                    ErrorView(
                        errorMessage: viewModel.errorMessage,
                        rawResponse: viewModel.rawResponse
                    )
                case .content:
                    if let plan = viewModel.healthPlan {
                        PlanContentView(plan: plan)
                    }
                case .empty:
                    EmptyPlanView()
                }
            }
            .navigationTitle("생성된 플랜")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.shouldShowRawResponseButton {
                        Button("원본 응답") {
                            viewModel.showRawResponseSheet()
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
            .sheet(isPresented: $viewModel.showRawResponse) {
                RawResponseView(rawResponse: viewModel.rawResponse)
            }
        }
    }
}

#Preview {
    AIScheduleResultView(
        viewModel: AIScheduleResultViewModel(
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
    )
}
