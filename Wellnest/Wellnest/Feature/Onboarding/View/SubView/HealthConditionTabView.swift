//
//  HealthConditionTabView.swift
//  Wellnest
//
//  Created by 정소이 on 8/6/25.
//

import SwiftUI

struct HealthConditionTabView: View {
    @ObservedObject var userDefaultsManager: UserDefaultsManager
    @Binding var currentPage: Int

    @State private var conditions = HealthCondition.conditions

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.layout),
        GridItem(.flexible(), spacing: Spacing.layout)
    ]

    private var cardWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        return (screenWidth - (Spacing.layout * 3)) / 2
    }

    var isButtonDisabled: Bool {
        !conditions.contains(where: { $0.isSelected })
    }

    var body: some View {
        VStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    OnboardingTitle(title: "현재 건강 상태", description: "현재 건강 상태에 해당하는 특별한 이슈가 있나요?", currentPage: currentPage, onBack: { withAnimation { currentPage -= 1 } })

                    VStack {
                        HStack {
                            Text("* 중복 선택 가능")
                                .font(.caption2)
                            Spacer()
                        }
                        .padding(.horizontal, Spacing.content)
                        .padding(.bottom, Spacing.content)

                        LazyVGrid(columns: columns, spacing: Spacing.layout) {
                            ForEach($conditions) { $condition in
                                Button {
                                    withAnimation(.easeInOut) {
                                        condition.isSelected.toggle()
                                    }
                                } label: {
                                    VStack(spacing: Spacing.inline) {
                                        if let icon = condition.icon, !icon.isEmpty {
                                            Text(icon)
                                                .font(.system(size: 60))
                                        }

                                        Text(condition.category)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.black)
                                    }
                                    .frame(width: cardWidth, height: cardWidth)
                                    .background(condition.isSelected ? .accentCardYellow : .customSecondary)
                                    .cornerRadius(CornerRadius.large)
                                }
                                .defaultShadow()
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
                .scrollIndicators(.hidden)

                FilledButton(title: "완료") {
                    userDefaultsManager.isOnboarding = true
                }
                .disabled(isButtonDisabled)
                .opacity(isButtonDisabled ? 0.5 : 1.0)
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }
}

#Preview {
    Preview()
}

private struct Preview: View {
    @State private var currentPage = 0

    var body: some View {
        HealthConditionTabView(userDefaultsManager: UserDefaultsManager.shared, currentPage: $currentPage)
    }
}
