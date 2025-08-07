//
//  WellnessGoalTabView.swift
//  Wellnest
//
//  Created by 정소이 on 8/4/25.
//

import SwiftUI

struct WellnessGoalTabView: View {
    @Binding var currentPage: Int
    
    @State private var goals = WellnessGoal.goals

    var isButtonDisabled: Bool {
        !goals.contains(where: { $0.isSelected })
    }

    var body: some View {
        VStack {
            OnboardingTitle(title: "웰니스 목표", description: "삶의 질을 높이고 지속 가능한 건강 루틴을 만드는 것에 집중해보세요.", currentPage: currentPage, onBack: { withAnimation { currentPage -= 1 } })

            VStack {
                HStack {
                    Text("* 중복 선택 가능")
                        .font(.caption2)
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
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(goal.isSelected ? .accentCardYellow : .customSecondary)
                        .cornerRadius(CornerRadius.large)
                    }
                    .padding(.bottom, Spacing.content)
                    .defaultShadow()
                }
            }
            .padding(.horizontal)

            Spacer()

            FilledButton(title: "다음") {
                withAnimation {
                    currentPage += 1
                }
            }
            .disabled(isButtonDisabled)
            .opacity(isButtonDisabled ? 0.5 : 1.0)
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

#Preview {
    Preview()
}

private struct Preview: View {
    @State private var currentPage = 0

    var body: some View {
        WellnessGoalTabView(currentPage: $currentPage)
    }
}
