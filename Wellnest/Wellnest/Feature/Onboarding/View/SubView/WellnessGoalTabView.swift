//
//  WellnessGoalTabView.swift
//  Wellnest
//
//  Created by 정소이 on 8/4/25.
//

import SwiftUI

struct WellnessGoal: Identifiable {
    let id = UUID()
    let title: String
    var isSelected: Bool = false
}

struct WellnessGoalTabView: View {
    @Binding var currentPage: Int
    
    @State private var goals: [WellnessGoal] = [
        WellnessGoal(title: "🧘🏾  마음의 안정과 스트레스 관리"),
        WellnessGoal(title: "Cycling"),
        WellnessGoal(title: "Camera"),
        WellnessGoal(title: "Golf"),
        WellnessGoal(title: "Music"),
        WellnessGoal(title: "Travel")
    ]

    var body: some View {
        VStack {
            OnboardingTitle(title: "웰니스 목표", description: "삶의 질을 높이고 지속 가능한 건강 루틴을 만드는 것에 집중해보세요.")

            VStack {
                HStack {
                    Text("중복 선택 가능")
                        .font(.caption2)
                    Spacer()
                }
                .padding(.horizontal, Spacing.content)
                .padding(.bottom, Spacing.inline)

                VStack {
                    ForEach($goals) { $category in
                        Button {
                            category.isSelected.toggle()
                            // TODO: Core Data 저장 처리
                        } label: {
                            HStack {
                                Text(category.title)
                                    .font(.body)
                                    .foregroundColor(.primary)

                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                            .background(category.isSelected ? .accentCardGreen : .customSecondary)
                            .cornerRadius(CornerRadius.large)
                        }
                        .padding(.bottom, Spacing.content)
                        .defaultShadow()
                    }
                }

//                        HStack {
//                            Text("dd")
//                        }
//                        .frame(maxWidth: .infinity)
//                        .frame(height: 58)
//                        .background(.customSecondary)
//                        .cornerRadius(CornerRadius.large)
//                        .padding(.bottom, Spacing.content)
            }
            .padding(.horizontal)

            Spacer()

            FilledButton(title: "다음") {
                currentPage = 5
            }
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
