//
//  ScheduleCardView.swift
//  Wellnest
//
//  Created by JuYong Lee on 8/4/25.
//
import SwiftUI

struct ScheduleCardView: View {
    @EnvironmentObject var swipe: SwipeCoordinator
    @ObservedObject var manualScheduleVM: ManualScheduleViewModel
    @State private var isDeleting = false
    @State private var deleteOffset: CGFloat = 0
    @State private var isCompleted = false
    @State private var completedOffset: CGFloat = 0
    
    let schedule: ScheduleItem
    let scheduleWidth: CGFloat
    
    let maxSwipeDistance: CGFloat = 30
    let isDevice = UIDevice.current.userInterfaceIdiom == .pad
    
    private let calManager = CalendarManager.shared
    
    private var currentOffset: CGFloat {
        guard swipe.openId == schedule.id, let direction = swipe.direction else { return 0 }
        return direction == .right ? maxSwipeDistance : -maxSwipeDistance
    }
    
    private var animationOffset: CGFloat {
        if isDeleting { return deleteOffset }
        if isCompleted { return completedOffset }
        return currentOffset
    }
    
    private var  currentWidth: CGFloat {
        isDevice ? scheduleWidth : UIScreen.main.bounds.width - (Spacing.layout * 2)
    }
    
    private var reveal: CGFloat { abs(currentOffset) }
    
    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                if currentOffset > 0 {
                    Button {
                        withAnimation(.easeIn(duration: 0.3)) {
                            isDeleting = false
                            isCompleted = true
                            completedOffset = currentWidth + 30
                            swipe.offSwipe()
                        }
                        
                        Task {
                            // 애니메이션 효과 이후 업데이트를 위한 sleep
                            try? await Task.sleep(for: .milliseconds(300))
                            
                            withAnimation(.easeInOut) {
                                manualScheduleVM.updateCompleted(item: schedule)
                            }
                        }
                    } label: {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.black)
                            .frame(maxHeight: .infinity)
                            .frame(width: 50)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.large)
                            .fill(Color.scheduleBackground(color: schedule.backgroundColor))
                    )
                    
                    Spacer()
                } else if currentOffset < 0 {
                    Spacer()
                    
                    Button {
                        withAnimation(.easeIn(duration: 0.3)) {
                            isDeleting = true
                            isCompleted = false
                            deleteOffset = -currentWidth - 30
                            swipe.offSwipe()
                        }
                        
                        Task {
                            // 애니메이션 효과 이후 삭제를 위한 sleep
                            try? await Task.sleep(for: .milliseconds(300))
                            
                            // Core Data에서 일정 삭제
                            withAnimation(.easeInOut) {
                                manualScheduleVM.deleteSchedule(item: schedule)
                            }
                        }
                    } label: {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.white)
                            .frame(maxHeight: .infinity)
                            .frame(width: 50)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.large)
                            .fill(.red)
                    )
                }
            }
            .frame(width: currentWidth)
            .disabled(isDeleting || isCompleted)
            
            ScheduleItemView(schedule: schedule, showOnlyPlanView: false)
                .frame(width: currentWidth - abs(currentOffset) - (currentOffset == 0  ? 0 : (isDevice ? Spacing.layout * 1.9 : Spacing.layout * 1.8)))
                .offset(x: animationOffset)
                .gesture(
                    DragGesture(minimumDistance: 35)
                        .onChanged { value in
                            let horizontal = value.translation.width
                            let vertical = value.translation.height
                            
                            guard abs(horizontal) > abs(vertical) else { return }
                            
                            let direction = horizontal > 0 ? SwipeDirection.right : SwipeDirection.left
                            if swipe.openId != schedule.id || swipe.direction != direction {
                                swipe.onSwipe(id: schedule.id, direction: direction)
                            }
                        }
                        .onEnded { value in
                            let horizontal = value.translation.width
                            let vertical = value.translation.height
                            
                            guard abs(horizontal) > abs(vertical) else {
                                swipe.offSwipe()
                                return
                            }
                            
                            if abs(horizontal) > maxSwipeDistance / 2 {
                                let direction = horizontal > 0 ? SwipeDirection.right : SwipeDirection.left
                                swipe.onSwipe(id: schedule.id, direction: direction)
                            } else {
                                swipe.offSwipe()
                            }
                        },
                    including: .gesture
                )
                .simultaneousGesture(
                    TapGesture().onEnded {
                        swipe.offSwipe()
                    }
                )
                .animation(.easeInOut, value: currentOffset)
                .animation(.easeInOut, value: animationOffset)
        }
    }
}
