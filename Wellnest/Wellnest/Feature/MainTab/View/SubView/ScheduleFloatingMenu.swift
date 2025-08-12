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
    
    @State private var showAI = false
    @State private var showManual = false
    @State private var revealTask: Task<Void, Never>?
    
    var body: some View {
        VStack(spacing: Spacing.layout) {
            Spacer()
            
            if showScheduleMenu {
                if showAI {
                    Button {
                        selectedType = .createByAI
                    } label: {
                        Label("AI 일정 생성", systemImage: "sparkles")
                            .padding(Spacing.content)
                            .background(.thinMaterial)
                            .clipShape(Capsule())
                            .defaultShadow()
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                if showManual {
                    Button {
                        selectedType = .createByUser
                    } label: {
                        Label("직접 일정 생성", systemImage: "pencil")
                            .padding(Spacing.content)
                            .background(.thinMaterial)
                            .clipShape(Capsule())
                            .defaultShadow()
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onChange(of: showScheduleMenu) { newValue in
            if newValue {
                startAnimateMenu()
            } else {
                stopAnimateMenu()
            }
        }
        .onAppear {
            if showScheduleMenu {
                startAnimateMenu()
            }
        }
        .onDisappear {
            stopAnimateMenu()
        }
    }
    
    private func startAnimateMenu() {
        stopAnimateMenu()
        
        revealTask = Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            await MainActor.run { withAnimation(.spring()) { showManual = true } }
            
            try? await Task.sleep(nanoseconds: 200_000_000)
            await MainActor.run { withAnimation(.spring()) { showAI = true } }
        }
    }
    
    private func stopAnimateMenu() {
        revealTask?.cancel()
        revealTask = nil
        
        showAI = false
        showManual = false
    }
}

//#Preview {
//    ScheduleFloatingMenu(selectedType: .constant(nil), showScheduleMenu: .constant(true))
//}

#Preview {
    MainTabView()
}
