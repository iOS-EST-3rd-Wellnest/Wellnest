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
                Spacer()
                    .frame(width: 40 + Spacing.layout*2)
                tabButton(tab: .analysis)
                tabButton(tab: .settings)
            }
            .padding(.vertical, Spacing.content)
            .padding(.horizontal)
            //            .background(.ultraThinMaterial)
            .background {
                GeometryReader { geo in
                    ZStack {
                        Capsule()
                            .fill(.ultraThinMaterial)
                        
                        Circle()
                            .frame(width: 80, height: 80)
                            .position(x: geo.size.width / 2, y: 0)
                            .blendMode(.destinationOut)
                    }
                    .compositingGroup()
                    .defaultShadow()
                }
            }
            .clipShape(Capsule())
            .defaultShadow()
            .padding(.horizontal)
            
            Button {
                
                showScheduleMenu.toggle()
                
            } label: {
                Image(systemName: "plus")
                    .resizable()
                    .fontWeight(.semibold)
                    .frame(width: 40, height: 40)
                //                    .font(.system(size: 40, weight: .bold))
                    .padding(12)
                    .background {
                        Circle()
                            .fill(Color.accentColor)
                    }
                    .foregroundStyle(.white)
                    .defaultShadow()
            }
            .offset(y: -(20 + Spacing.content))
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
