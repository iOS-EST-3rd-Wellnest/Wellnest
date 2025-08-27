//
//  HomeScheduleView.swift
//  Wellnest
//
//  Created by JuYong Lee on 8/26/25.
//
import SwiftUI

struct HomeScheduleView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var swipe = SwipeCoordinator()
    @ObservedObject var manualScheduleVM: ManualScheduleViewModel
    
    let isCompleteSchedules: [ScheduleItem]
    var scheduleWidth: CGFloat = .zero
    
    private var isDivicePad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(isCompleteSchedules) { schedule in
                    ScheduleCardView(manualScheduleVM: manualScheduleVM, schedule: schedule, scheduleWidth: scheduleWidth)
                        .environmentObject(swipe)
                        .padding(.vertical, Spacing.content)
            }
        }
    }
}

struct EmptyScheduleView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var height: CGFloat = 100
    
    var body: some View {
        RoundedRectangle(cornerRadius: CornerRadius.large)
            .fill(colorScheme == .dark ? Color(.systemGray6) : .white)
            .frame(height: height)
            .roundedBorder(cornerRadius: CornerRadius.large)
            .defaultShadow()
            .overlay {
                Text("일정을 추가 해주세요.")
                    .frame(maxWidth: .infinity)
            }
    }
}
