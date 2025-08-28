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

    private let circleSize: CGFloat = 44

    var body: some View {
        VStack(spacing: Spacing.layout) {
            Spacer()
            
            if showScheduleMenu {
                if showAI {
                    Button { selectedType = .createByAI } label: {
                        menuRow(title: "AI 일정 생성", systemName: "sparkles")
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                if showManual {
                    Button { selectedType = .createByUser } label: {
                        menuRow(title: "직접 일정 생성", systemName: "pencil")
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

    @ViewBuilder
    private func menuRow(title: String, systemName: String) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                Circle()
                    .fill(.wellnestOrange)
                    .frame(width: circleSize, height: circleSize)
                    .overlay(
                        Image(systemName: systemName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    )
                    .defaultShadow(color: .wellnestOrange.opacity(0.4), radius: 4)
                    .position(x: geo.size.width / 2, y: circleSize / 2)

                Text(title)
                    .font(.body)
                    .foregroundStyle(.wellnestSelected)
                    .frame(height: circleSize, alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, geo.size.width / 2 + circleSize / 2 + Spacing.content)
            }
            .frame(height: circleSize)
            .contentShape(Rectangle())
        }
        .frame(height: circleSize)
        .padding(.horizontal, Spacing.content)
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

#Preview {
    MainTabView()
}
