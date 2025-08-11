//
//  WellnessGoalTabView.swift
//  Wellnest
//
//  Created by 정소이 on 8/4/25.
//

import SwiftUI

struct WellnessGoalTabView: View {
    var userEntity: UserEntity
    var viewModel: UserInfoViewModel

    @Binding var currentPage: Int
    @Binding var title: String

    @State private var goals = WellnessGoal.goals

    let spacing = OnboardingCardLayout.spacing

    var isButtonDisabled: Bool {
        !goals.contains(where: { $0.isSelected })
    }

    var body: some View {
        VStack {
            OnboardingTitleDescription(description: "삶의 질을 높이고 지속 가능한 건강 루틴을 만드는 것에 집중해보세요.")

            VStack {
                HStack {
                    Text("* 중복 선택 가능")
                        .font(.caption2)
                        .foregroundColor(.primary.opacity(0.5))
                    Spacer()
                }
                .padding(.horizontal, Spacing.content)
                .padding(.bottom, Spacing.content)

                ForEach($goals) { $goal in
                    Button {
                        withAnimation(.easeInOut) {
                            goal.isSelected.toggle()
                        }
                    } label: {
                        HStack {
                            Text(goal.title)
                                .fontWeight(.semibold)
                                .foregroundColor(goal.isSelected ? .white : .secondary)
                                .padding(.leading)

                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(goal.isSelected ? .blue : .customSecondary)
                        .cornerRadius(CornerRadius.large)
                    }
                    .padding(.bottom, Spacing.content)
                    .defaultShadow()
                }
            }
            .padding(.horizontal, spacing)

            Spacer()

            FilledButton(title: "다음") {
                saveWellnessGoal()
                withAnimation {
                    currentPage += 1
                }
            }
            .disabled(isButtonDisabled)
            .opacity(isButtonDisabled ? 0.5 : 1.0)
            .padding()
        }
        .onAppear {
            title = "웰니스 목표"
        }
    }
}

extension WellnessGoalTabView {
    private func saveWellnessGoal() {
        let selectedGoals = goals.filter { $0.isSelected }

        if selectedGoals.contains(where: { $0.title.withoutPrefix3 == "특별히 없음" }) {
            userEntity.goal = nil
        } else {
            let goals = selectedGoals.map { $0.title.withoutPrefix3 }.joined(separator: ", ")
            userEntity.goal = goals
        }

        print(userEntity)
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
