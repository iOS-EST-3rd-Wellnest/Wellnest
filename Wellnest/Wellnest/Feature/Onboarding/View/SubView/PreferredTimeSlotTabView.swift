//
//  PreferredTimeSlotTabView.swift
//  Wellnest
//
//  Created by 정소이 on 8/5/25.
//

import SwiftUI

struct PreferredTimeSlotTabView: View {
    @Binding var currentPage: Int

    @State private var timeSlots = PreferredTimeSlot.timeSlots

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.layout),
        GridItem(.flexible(), spacing: Spacing.layout)
    ]

    private var cardWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        return (screenWidth - (Spacing.layout * 3)) / 2
    }

    var isButtonDisabled: Bool {
        !timeSlots.contains(where: { $0.isSelected })
    }

    var body: some View {
        VStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    OnboardingTitle(title: "활동 시간대", description: "앞에서 선택하신 활동은 주로 언제 하시나요?", currentPage: currentPage, onBack: { withAnimation { currentPage -= 1 } })

                    VStack {
                        HStack {
                            Text("* 중복 선택 가능")
                                .font(.caption2)
                            Spacer()
                        }
                        .padding(.horizontal, Spacing.content)
                        .padding(.bottom, Spacing.content)

                        LazyVGrid(columns: columns, spacing: Spacing.layout) {
                            ForEach($timeSlots) { $timeSlot in
                                Button {
                                    withAnimation(.easeInOut) {
                                        timeSlot.isSelected.toggle()
                                    }
                                } label: {
                                    VStack(spacing: Spacing.inline) {
                                        if let icon = timeSlot.icon, !icon.isEmpty {
                                            Text(icon)
                                                .font(.system(size: 60))
                                        }

                                        Text(timeSlot.category)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                    }
                                    .frame(width: cardWidth, height: cardWidth)
                                    .background(timeSlot.isSelected ? .accentCardYellow : .customSecondary)
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
}

#Preview {
    Preview()
}

private struct Preview: View {
    @State private var currentPage = 0

    var body: some View {
        PreferredTimeSlotTabView(currentPage: $currentPage)
    }
}
