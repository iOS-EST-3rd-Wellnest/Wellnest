//
//  CustomTabBar.swift
//  Wellnest
//
//  Created by 박동언 on 8/1/25.
//

import SwiftUI

struct CustomTabBar: View {
    @Environment(\.colorScheme) var colorScheme

    @Binding var selectedTab: TabBarItem
    @Binding var showScheduleMenu: Bool

    @State private var barHeight: CGFloat = 0

    var body: some View {
        ZStack {
            HStack {
                tabButton(tab: .home)
                tabButton(tab: .plan)
                Spacer()
                    .frame(width: 40 + Spacing.layout*2)
                tabButton(tab: .analysis)
                tabButton(tab: .settings)
            }
            .padding(.vertical, Spacing.content)
            .padding(.horizontal)
            .background {
                GeometryReader { geo in
                    ZStack {
                        Capsule()
                            .fill(.wellnestTabBar)

                        Circle()
                            .frame(width: 70, height: 70)
                            .position(x: geo.size.width / 2, y: 0)
                            .blendMode(.destinationOut)
                    }
                    .onAppear { barHeight = geo.size.height }
                    .onChange(of: geo.size.height) { barHeight = $0 }
                    .compositingGroup()
                }
            }
            .clipShape(Capsule())
            .if(colorScheme == .light) { view in
                    view.defaultShadow(color: .secondary.opacity(0.5), radius: 4 , x: 2, y: 2)
            }
            .padding(.horizontal)

            Button {
                showScheduleMenu.toggle()
            } label: {
                Image(systemName: "plus")
                    .resizable()
                    .fontWeight(.semibold)
                    .frame(width: 32, height: 32)
                    .padding(12)
                    .background {
                        Circle()
                            .fill(.wellnestOrange)
                    }
                    .foregroundStyle(.white)

            }
            .defaultShadow(color: .wellnestOrange.opacity(0.4), radius: 4)
            .offset(y: -(barHeight / 2))
        }
    }
    
    @ViewBuilder
    private func tabButton(tab: TabBarItem) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: Spacing.inline) {
                Image(systemName: tab.iconName)
                    .symbolRenderingMode(.hierarchical)
                    .font(.title3)
                    .imageScale(.medium)

                Text(tab.title)
                    .font(.footnote.weight(.semibold))
                    .lineLimit(1)

            }
            .foregroundStyle(selectedTab == tab ? .wellnestSelected : .wellnestTabItem)

        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    CustomTabBar(selectedTab: .constant(.home), showScheduleMenu: .constant(false))
}
