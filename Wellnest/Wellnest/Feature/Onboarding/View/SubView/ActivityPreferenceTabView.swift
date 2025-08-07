//
//  ActivityPreferenceTabView.swift
//  Wellnest
//
//  Created by 정소이 on 8/5/25.
//

import SwiftUI

struct ActivityPreferenceTabView: View {
    @Binding var currentPage: Int

    @State private var activities = ActivityPreference.activities

    let columns = OnboardingCardLayout.columns
    let cardWidth = OnboardingCardLayout.cardWidth

    var isButtonDisabled: Bool {
        !activities.contains(where: { $0.isSelected })
    }

    var body: some View {
        VStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    OnboardingTitle(title: "선호 활동", description: "평소에 선호하는 운동이나 활동을 골라주세요.", currentPage: currentPage, onBack: { withAnimation { currentPage -= 1 } })

                    VStack {
                        HStack {
                            Text("* 중복 선택 가능")
                                .font(.caption2)
                            Spacer()
                        }
                        .padding(.horizontal, Spacing.content)
                        .padding(.bottom, Spacing.content)

                        LazyVGrid(columns: columns, spacing: Spacing.layout) {
                            ForEach($activities) { $activity in
                                Button {
                                    withAnimation(.easeInOut) {
                                        activity.isSelected.toggle()
                                    }
                                } label: {
                                    VStack(spacing: Spacing.inline) {
                                        if let icon = activity.icon, !icon.isEmpty {
                                            Text(icon)
                                                .font(.system(size: 60))
                                        }

                                        Text(activity.category)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.black)
                                    }
                                    .frame(width: cardWidth, height: cardWidth)
                                    .background(activity.isSelected ? .accentCardYellow : .customSecondary)
//                                    .background(activity.isSelected ? activity.randomCardColor : .customSecondary)
                                    .cornerRadius(CornerRadius.large)
                                }
                                .defaultShadow()
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .scrollIndicators(.hidden)
                .safeAreaInset(edge: .bottom) {
                    FilledButton(title: "다음") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .disabled(isButtonDisabled)
                    .opacity(isButtonDisabled ? 0.5 : 1.0)
                    .padding()
                    .background(.white)
                }
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
        ActivityPreferenceTabView(currentPage: $currentPage)
    }
}
