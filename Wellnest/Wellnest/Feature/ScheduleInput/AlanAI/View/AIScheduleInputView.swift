//
//  AIScheduleInputView.swift
//  Wellnest
//
//  Created by junil on 8/4/25.
//

import SwiftUI

struct AIScheduleInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selectedTab: TabBarItem
    @Binding var selectedCreationType: ScheduleCreationType?
    @StateObject private var viewModel = AIScheduleViewModel()

    private let isDevicePad = UIDevice.current.userInterfaceIdiom == .pad

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.section) {
                    PlanTypeSelectionSection(
                        selectedPlanType: $viewModel.selectedPlanType,
                        onPlanTypeChanged: { viewModel.selectPlanType($0) }
                    )

                    dateTimeInputSection

                    PreferencesSelectionSection(
                        selectedPreferences: $viewModel.selectedPreferences
                    )
                }
                .padding(.horizontal, Spacing.layout)
                .padding(.vertical, Spacing.layout)
            }
            .navigationTitle("플랜 생성")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        selectedCreationType = nil
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.wellnestOrange)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    generateButton
                        .padding()
                        .tabBarGlassBackground()
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            .frame(width: isDevicePad ? 600 : UIScreen.main.bounds.width)

        }
        .fullScreenCover(isPresented: $viewModel.showResult) {
            AIScheduleResultView(
                viewModel: viewModel,
                selectedTab: $selectedTab,
                selectedCreationType: $selectedCreationType,
                parentDismiss: dismiss
            )
        }
    }

    private var dateTimeInputSection: some View {
        VStack(alignment: .leading, spacing: Spacing.layout) {
            switch viewModel.selectedPlanType {
            case .single:
                SinglePlanDateTimeSection(
                    singleDate: $viewModel.singleDate,
                    singleStartTime: $viewModel.singleStartTime,
                    singleEndTime: $viewModel.singleEndTime,
                    onStartTimeChange: viewModel.updateSingleStartTime
                )
            case .multiple:
                MultiplePlanDateTimeSection(
                    multipleStartDate: $viewModel.multipleStartDate,
                    multipleEndDate: $viewModel.multipleEndDate,
                    multipleStartTime: $viewModel.multipleStartTime,
                    multipleEndTime: $viewModel.multipleEndTime,
                    onStartTimeChange: viewModel.updateMultipleStartTime
                )
            case .routine:
                RoutinePlanDateTimeSection(
                    selectedWeekdays: $viewModel.selectedWeekdays,
                    routineStartDate: $viewModel.routineStartDate,
                    routineEndDate: $viewModel.routineEndDate,
                    routineStartTime: $viewModel.routineStartTime,
                    routineEndTime: $viewModel.routineEndTime,
                    onWeekdayToggle: viewModel.toggleWeekday,
                    onStartTimeChange: viewModel.updateRoutineStartTime
                )
            }
        }
    }

    private var generateButton: some View {
        FilledButton(title: viewModel.isLoading ? "플랜 생성 중..." : "플랜 생성하기") {
            viewModel.generatePlan()
        }
        .disabled(!viewModel.isValidInput || viewModel.isLoading)
        .opacity((!viewModel.isValidInput || viewModel.isLoading) ? 0.5 : 1.0)
    }
}

extension Spacing {
    static let section: CGFloat = 24
}
