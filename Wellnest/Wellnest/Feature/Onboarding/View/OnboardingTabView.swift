//
//  OnboardingTableView.swift
//  Wellnest
//
//  Created by 정소이 on 8/1/25.
//

import SwiftUI

struct OnboardingTabView: View {
    @ObservedObject var userDefaultsManager: UserDefaultsManager

    @StateObject private var viewModel = UserInfoViewModel()

    @State private var currentPage: Int = 0
    @State private var title: String = ""

    var body: some View {
        NavigationView {
            VStack {
                if let user = viewModel.userEntity {
                    switch currentPage {
                    case 0:
                        MotivationTabView(currentPage: $currentPage, title: $title)
                    case 1, 2:
                        IntroductionTabView(currentPage: $currentPage, title: $title)
                    case 3:
                        UserInfoTabView(userEntity: user, currentPage: $currentPage, title: $title)
                    case 4:
                        WellnessGoalTabView(userEntity: user, viewModel: viewModel, currentPage: $currentPage, title: $title)
                    case 5:
                        ActivityPreferenceTabView(userEntity: user, viewModel: viewModel, currentPage: $currentPage, title: $title)
                    case 6:
                        PreferredTimeSlotTabView(userEntity: user, viewModel: viewModel, currentPage: $currentPage, title: $title)
                    case 7:
                        WeatherPreferenceTabView(userEntity: user, viewModel: viewModel, currentPage: $currentPage, title: $title)
                    case 8:
                        HealthConditionTabView(userEntity: user, viewModel: viewModel, userDefaultsManager: UserDefaultsManager.shared, currentPage: $currentPage, title: $title)
                    default:
                        EmptyView()
                    }
                } else {
                    if currentPage == 0 {
                        MotivationTabView(currentPage: $currentPage, title: $title)
                    } else if currentPage == 1 || currentPage == 2 {
                        IntroductionTabView(currentPage: $currentPage, title: $title)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if currentPage > 0 {
                        Button {
                            withAnimation { currentPage -= 1 }
                        } label: {
                            Image(systemName: "chevron.backward")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct OnboardingTitleDescription: View {
    let description: String

    var body: some View {
        Text(description)
            .foregroundColor(.primary.opacity(0.7))
            .multilineTextAlignment(.center)
            .padding(.top, Spacing.content)
            .padding(.horizontal)
            .padding(.bottom, 60)
    }
}

struct OnboardingCardLayout {
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    static var columnCount: Int {
        isIPad ? 3 : 2
    }

    static var spacing: CGFloat {
        isIPad ? 25 : Spacing.layout
    }

    static var spacingCount: CGFloat {
        isIPad ? 4 : 3
    }

    static var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount)
    }

    static var cardWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        return (screenWidth - (spacing * spacingCount)) / CGFloat(columnCount)
    }
}

struct ToggleCardHelper {
    static func toggleCard<Item: SelectableItem>(item: Binding<Item>, items: Binding<[Item]>) {
        withAnimation(.easeInOut) {
            if item.wrappedValue.title == "특별히 없음" {
                // "특별히 없음" 선택 시, 다른 선택 전부 해제
                if !item.wrappedValue.isSelected { // 현재 선택 안돼있으면
                    for index in items.indices {
                        items.wrappedValue[index].isSelected = false
                    }
                    item.wrappedValue.isSelected = true
                } else {
                    // 다시 누르면 해제
                    item.wrappedValue.isSelected = false
                }
            } else {
                // 다른 목표 선택 시, "특별히 없음" 해제
                if let noneIndex = items.wrappedValue.firstIndex(where: { $0.title == "특별히 없음" }) {
                    items.wrappedValue[noneIndex].isSelected = false
                }
                item.wrappedValue.isSelected.toggle()
            }
        }
    }
}

struct OnboardingCardContent<Item: SelectableItem>: View {
    @Binding var items: [Item]

    let columns = OnboardingCardLayout.columns
    let cardWidth = OnboardingCardLayout.cardWidth
    let spacing = OnboardingCardLayout.spacing

    var body: some View {
        VStack {
            HStack {
                Text("* 중복 선택 가능")
                    .font(.caption2)
                    .foregroundColor(.primary.opacity(0.5))
                Spacer()
            }
            .padding(.horizontal, Spacing.content)
            .padding(.bottom, Spacing.content)

            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach($items, id: \.id) { $item in
                    Button {
                        ToggleCardHelper.toggleCard(item: $item, items: $items)
                    } label: {
                        VStack(spacing: Spacing.inline) {
                            Text(item.icon)
                                    .font(.system(size: 60))
                                    .saturation(item.isSelected ? 1 : 0) // 채도 조절

                            Text(item.title)
                                .fontWeight(.semibold)
                                .foregroundColor(item.isSelected ? .black : .gray)
                        }
                        .frame(width: cardWidth, height: cardWidth)
                        .background(item.isSelected ? .customGray : .customSecondary)
                        .cornerRadius(CornerRadius.large)
                    }
                    .defaultShadow()
                }
            }
        }
        .padding(.horizontal, spacing)
        .padding(.bottom)
    }
}

struct OnboardingButton: View {
    @Environment(\.colorScheme) var colorScheme

    let title: String
    let isDisabled: Bool
    let action: () -> Void

    @Binding var currentPage: Int

    var showPrevious: Bool = false
    var isLastStep: Bool = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            LinearGradient(
                gradient: Gradient(colors: [
                    (colorScheme == .dark ? Color.black : Color.white).opacity(0.0),
                    (colorScheme == .dark ? Color.black : Color.white).opacity(1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 24)

            HStack {
                if showPrevious, currentPage > 0 {
                    FilledButton(
                        title: "이전",
                        disabled: false,
                        action: { withAnimation { currentPage -= 1 } }
                    )
                }

                FilledButton(
                    title: title,
                    disabled: isDisabled,
                    action: {
                        action()
                        if isLastStep {
                            dismiss() // 마지막 단계면 닫기
                        }
                    }
                )
            }
            .padding(.horizontal)
            .padding(.bottom, Spacing.content)
            .background(colorScheme == .dark ? Color.black : Color.white)
        }
    }
}

#Preview {
    OnboardingTabView(userDefaultsManager: UserDefaultsManager.shared)
}
