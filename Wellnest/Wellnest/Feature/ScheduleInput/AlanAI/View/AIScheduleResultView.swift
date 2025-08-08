//
//  AIScheduleResultView.swift
//  Wellnest
//
//  Created by junil on 8/4/25.
//

import SwiftUI

struct AIScheduleResultView: View {
    @ObservedObject var viewModel: AIScheduleViewModel
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
                    VStack(spacing: 16) {
                        if viewModel.errorMessage.contains("I'm sorry, I can't assist") {
                            VStack(spacing: 12) {
                                Text("AI 서비스가 일시적으로 요청을 처리할 수 없습니다.")
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.secondary)

                                Text("잠시 후 다시 시도해주세요.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Button("다시 시도") {
                                    dismiss()
                                }
                                .buttonStyle(.borderedProminent)
                                .padding(.top)
                            }
                        } else {
                            ErrorView(
                                errorMessage: viewModel.errorMessage,
                                rawResponse: viewModel.rawResponse
                            )
                        }
                    }
                    .padding()
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
                    if !viewModel.errorMessage.isEmpty && !viewModel.rawResponse.isEmpty {
                        Button("원본 응답") {
                            // Show raw response
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
            .alert("저장 완료", isPresented: $viewModel.saveSuccess) {
                Button("확인") {
                    selectedTab = .plan
                    selectedCreationType = nil
                    dismiss()
                    parentDismiss()
                }
            } message: {
                Text("AI 플랜이 성공적으로 저장되었습니다.")
            }
            .alert("저장 실패", isPresented: .constant(!viewModel.saveError.isEmpty)) {
                Button("확인") {
                    viewModel.saveError = ""
                }
            } message: {
                Text("플랜 저장 중 오류가 발생했습니다: \(viewModel.saveError)")
            }
        }
        .onAppear {
            print("📱 AIScheduleResultView 나타남 - healthPlan: \(viewModel.healthPlan?.title ?? "없음")")
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

            FilledButton(title: viewModel.isSaving ? "저장 중..." : "저장하기") {
                viewModel.saveAISchedules()
            }
            .disabled(viewModel.isSaving)
            .opacity(viewModel.isSaving ? 0.6 : 1.0)
        }
    }
}
