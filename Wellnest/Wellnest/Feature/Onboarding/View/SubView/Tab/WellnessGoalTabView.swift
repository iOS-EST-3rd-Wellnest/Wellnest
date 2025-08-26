//
//  WellnessGoalTabView.swift
//  Wellnest
//
//  Created by 정소이 on 8/4/25.
//

import SwiftUI

struct WellnessGoalTabView: View {
    @Environment(\.colorScheme) var colorScheme

    var userEntity: UserEntity

    @ObservedObject var viewModel: UserInfoViewModel

    @Binding var currentPage: Int
    @Binding var title: String

    var isButtonDisabled: Bool {
        !viewModel.wellnessGoals.contains(where: { $0.isSelected })
    }

    var body: some View {
        ScrollView {
            OnboardingTitleDescription(description: "삶의 질을 높이고 지속 가능한 건강 루틴을 만드는 것에 집중해보세요")

            VStack {
                HStack {
                    Text("* 중복 선택 가능")
                        .font(.caption2)
                        .foregroundColor(.primary.opacity(0.5))
                    Spacer()
                }
                .padding(.horizontal, Spacing.content)
                .padding(.bottom, Spacing.content)

                ForEach($viewModel.wellnessGoals, id: \.id) { $goal in
                    Button {
                        ToggleCardHelper.toggleCard(item: $goal, items: $viewModel.wellnessGoals)
                    } label: {
                        HStack {
                            Text(goal.icon)
                                .padding(.leading)
                                .saturation(goal.isSelected ? 1 : 0)

                            Text(goal.title)
                                .fontWeight(.semibold)
                                .foregroundColor(goal.isSelected ? .primary : .gray)

                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(goal.isSelected ? (colorScheme == .dark ? Color(.systemGray4) : Color(.systemGray5)) : (colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6).opacity(0.5)))
                        .cornerRadius(CornerRadius.large)
                    }
                }
                .padding(.bottom, Spacing.content)
            }
            .padding(.horizontal, Spacing.layout)
        }
        .background(Color(.systemBackground))
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            OnboardingButton(
                title: "다음",
                isDisabled: isButtonDisabled,
                action: {
                    saveWellnessGoal()
                    withAnimation { currentPage += 1 }
                },
                currentPage: $currentPage
            )
        }
        .onAppear {
            title = "웰니스 목표"
        }
    }
}

extension WellnessGoalTabView {
    /// CoreData 저장
    private func saveWellnessGoal() {
        let selectedGoals = viewModel.wellnessGoals.filter { $0.isSelected }

        if selectedGoals.contains(where: { $0.title == "특별히 없음" }) {
            userEntity.goal = nil
        } else {
            let goals = selectedGoals.map { $0.title }.joined(separator: ", ")
            userEntity.goal = goals
        }

        try? CoreDataService.shared.saveContext()
    }
}

#Preview {
    Preview()
}

private struct Preview: View {
    @StateObject private var userInfoVM = UserInfoViewModel()
    @State private var currentPage = 0
    @State private var title = ""

    var body: some View {
        if let userEntity = userInfoVM.userEntity {
            WellnessGoalTabView(
                userEntity: userEntity,
                viewModel: userInfoVM,
                currentPage: $currentPage,
                title: $title
            )
        } else {
            ProgressView("Loading...")
        }
    }
}
