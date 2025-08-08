//
//  ScheduleFloatingMenu.swift
//  Wellnest
//
//  Created by 박동언 on 8/3/25.
//

import SwiftUI

struct ScheduleFloatingMenu: View {
    @Binding var selectedType: ScheduleCreationType?
    @Binding var showScheduleMenu: Bool
    
    var body: some View {
        VStack(spacing: Spacing.layout) {
            Spacer()
            Button {
                withAnimation {
					showScheduleMenu = false
                }
            } label: {
                Image(systemName: "xmark")
                    .resizable()
                    .frame(width: 16, height: 16)
                    .padding(Spacing.content)
                    .background {
                        Circle()
                            .stroke(Color.blue, lineWidth: 1)
                    }
                    .background(.thinMaterial)
                    .clipShape(Circle())
                    .defaultShadow()
            }

            Button {
                selectedType = .createByAI
            } label: {
                Label("AI 일정 생성", systemImage: "sparkles")
                    .padding(Spacing.content)
                    .background(.thinMaterial)
                    .clipShape(Capsule())
                    .defaultShadow()
            }

            Button {
                selectedType = .createByUser
            } label: {
                Label("직접 일정 생성", systemImage: "pencil")
                    .padding(Spacing.content)
                    .background(.thinMaterial)
                    .clipShape(Capsule())
                    .defaultShadow()
            }
        }
        .transition(.move(edge: .bottom))
        .animation(.easeInOut, value: selectedType)
    }
}

#Preview {
    ScheduleFloatingMenu(selectedType: .constant(nil), showScheduleMenu: .constant(false))
}
