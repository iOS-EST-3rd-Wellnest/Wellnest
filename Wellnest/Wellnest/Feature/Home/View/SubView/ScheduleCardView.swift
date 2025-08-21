//
//  ScheduleCardView.swift
//  Wellnest
//
//  Created by JuYong Lee on 8/4/25.
//
import SwiftUI

struct ScheduleCardView: View {
    @ObservedObject var manualScheduleVM: ManualScheduleViewModel
    @EnvironmentObject var swipe: SwipeCoordinator
    
    @State private var isDeleting = false
    @State private var deleteOffset: CGFloat = 0
    
    @State private var isCompleted = false
    @State private var completedOffset: CGFloat = 0
    
    let schedule: ScheduleItem
    let maxSwipeDistance: CGFloat = 27
    
    private let calManager = CalendarManager.shared
    
    private var currentOffset: CGFloat {
        guard swipe.openId == schedule.id, let direction = swipe.direction else { return 0 }
        return direction == .right ? maxSwipeDistance : -maxSwipeDistance
    }
    
    private var cardWidth: CGFloat {
        UIScreen.main.bounds.width - (Spacing.layout * 2)
    }
    
    private var animationOffset: CGFloat {
        if isDeleting { return deleteOffset }
        if isCompleted { return completedOffset }
        return currentOffset
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                HStack(spacing: 0) {
                    if currentOffset > 0 {
                        Button {
                            withAnimation(.easeIn(duration: 0.3)) {
                                isDeleting = false
                                isCompleted = true
                                completedOffset = geo.size.width + 30
                                swipe.offSwipe()
                            }
                            
                            Task {
                                // 애니메이션 효과 이후 업데이트를 위한 sleep
                                try? await Task.sleep(for: .milliseconds(300))
                                await MainActor.run {
                                    withAnimation(.easeInOut) {
                                        manualScheduleVM.updateCompleted(item: schedule)
                                    }
                                }
                            }
                            
                        } label: {
                            Image(systemName: "checkmark")
                                .frame(width: 45, height: 70)
                                .foregroundStyle(.black)
                        }
                        .background(
                            Capsule()
                                .fill(Color(.systemGray6))
                        )
                        
                        Spacer()
                    } else if currentOffset < 0 {
                        Spacer()
                        
                        Button {
                            withAnimation(.easeIn(duration: 0.3)) {
                                isDeleting = true
                                isCompleted = false
                                deleteOffset = -geo.size.width - 30
                                swipe.offSwipe()
                            }
                            
                            performDeleteFlow()
                            
//                            Task {
//                                // 애니메이션 효과 이후 삭제를 위한 sleep
//                                try? await Task.sleep(for: .milliseconds(300))
//                                await MainActor.run {
//                                    withAnimation(.easeInOut) {
//                                        manualScheduleVM.deleteSchedule(item: schedule)
//                                        
//                                    }
//                                }
//                            }
                        } label: {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.white)
                                .frame(width: 45, height: 70)
                        }
                        .background(
                            Capsule()
                                .fill(.red)
                        )
                    }
                }
                .disabled(isDeleting || isCompleted)
                
                ScheduleItemView(schedule: schedule)
                    .frame(width: geo.size.width - abs(currentOffset) - (currentOffset == 0 ? 0 : Spacing.layout * 1.7))
                    .offset(x: animationOffset)
                    .gesture(
                        DragGesture(minimumDistance: 30)
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
            }
        }
        .animation(.easeInOut, value: animationOffset)
        .frame(height: 70)
    }
}

extension ScheduleCardView {
    private func performDeleteFlow() {
            Task {
                // 애니메이션 효과 이후 삭제를 위한 sleep
                try? await Task.sleep(for: .milliseconds(300))

                // 캘린더 삭제
                _ = await CalendarManager.shared.deleteEventOrBackfill(
                    identifier: schedule.eventIdentifier,
                    title: schedule.title,
                    location: nil,
                    isAllDay: schedule.isAllDay,
                    startDate: schedule.startDate,
                    endDate: schedule.endDate,
                    in: nil
                )

                // Core Data에서 일정 삭제
                await MainActor.run {
                    withAnimation(.easeInOut) {
                        manualScheduleVM.deleteSchedule(item: schedule)
                    }
                }
            }
        }
    }
