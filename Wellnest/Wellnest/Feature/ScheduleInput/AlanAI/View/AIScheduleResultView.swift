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
    @Binding var selectedTab: TabBarItem
    @Binding var selectedCreationType: ScheduleCreationType?
    let parentDismiss: DismissAction

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
                    Button("취소") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if viewModel.currentViewState == .content, let _ = viewModel.healthPlan {
                    saveButtonsSection
                        .padding()
                        .background(.white)
                        .ignoresSafeArea(.keyboard, edges: .bottom)
                }
            }
            .sheet(isPresented: $viewModel.showRawResponse) {
                RawResponseView(rawResponse: viewModel.rawResponse)
            }
        }
    }

    // MARK: - Save Buttons Section
    private var saveButtonsSection: some View {
        HStack(spacing: Spacing.layout) {
            Button {
                dismiss()
            } label: {
                Text("취소")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
            }

            FilledButton(title: "저장하기") {
                saveAISchedules()
                selectedTab = .plan
                selectedCreationType = nil
                dismiss()
                parentDismiss()
            }
        }
    }
}
