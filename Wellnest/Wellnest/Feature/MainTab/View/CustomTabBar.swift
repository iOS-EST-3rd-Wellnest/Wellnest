//
//  CustomTabBar.swift
//  Wellnest
//
//  Created by 박동언 on 8/1/25.
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: TabBarItem
    @Binding var showScheduleMenu: Bool

    var body: some View {
        ZStack {
            HStack {
                tabButton(tab: .home)
                tabButton(tab: .plan)
                 Spacer().frame(width: 60)
                tabButton(tab: .analysis)
                tabButton(tab: .settings)
            }
            .padding(.vertical, Spacing.content)
            .padding(.horizontal)
            .background(.ultraThinMaterial)
            //        .background {
            //            Color.accentCardBlue
            //                .background(.ultraThinMaterial)
            //        }
            .clipShape(Capsule())
            .defaultShadow()
            .padding(.horizontal)
            .padding(.bottom)

            Button {
                showScheduleMenu.toggle()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 40, weight: .bold))
                    .padding(Spacing.content)
                    .background {
                        Circle()
                            .fill(Color.accentColor)
                    }
                    .foregroundStyle(.white)
                    .defaultShadow()
            }
            .offset(y: -(Spacing.layout*2))
        }
    }

    @ViewBuilder
    private func tabButton(tab: TabBarItem) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: Spacing.inline) {
                Image(systemName: tab.iconName)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)

                Text(tab.title)
                    .font(.caption2)
            }
            .foregroundStyle(selectedTab == tab ? Color.accentColor : .black)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    CustomTabBar(selectedTab: .constant(.home), showScheduleMenu: .constant(false))
}
