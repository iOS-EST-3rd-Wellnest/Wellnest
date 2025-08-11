//
//  ScheduleCardView.swift
//  Wellnest
//
//  Created by JuYong Lee on 8/4/25.
//
import SwiftUI

// 좌우 스와이프 구분 열거형
enum SwipeDirection {
    case left, right
}

struct ScheduleCardView: View {
    @ObservedObject var manualScheduleVM: ManualScheduleViewModel
    
    @State private var isDeleting = false
    @State private var deleteOffset: CGFloat = 0

    @State private var isCompleted = false
    @State private var completedOffset: CGFloat = 0
    
    let schedule: ScheduleItem

    let swipedScheduleId: UUID?
    let swipedDirection: SwipeDirection?
    let onSwiped: (UUID?, SwipeDirection?) -> Void

    let maxSwipeDistance: CGFloat = 27
    
    var currentOffset: CGFloat {
        guard swipedScheduleId == schedule.id, let direction = swipedDirection else {
            return 0
        }
        switch direction {
        case .right:
            return maxSwipeDistance
        case .left:
            return -maxSwipeDistance
        }
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
                                onSwiped(nil, nil)
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
                                onSwiped(nil, nil)
                            }
                            
                            Task {
                                // 애니메이션 효과 이후 삭제를 위한 sleep
                                try? await Task.sleep(for: .milliseconds(300))
                                await MainActor.run {
                                    withAnimation(.easeInOut) {
                                        manualScheduleVM.deleteSchedule(item: schedule)
                                    }
                                }
                            }
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
                
                //            ScheduleItemView(schedule: schedule)
                VStack(alignment: .leading, spacing: Spacing.content) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .opacity(0.75)
                        
                        Text("\(schedule.startDate.formattedTime) ~ \(schedule.endDate.formattedTime)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    
                    Text(schedule.title)
                        .font(.headline)
                        .bold()
                        .padding(.horizontal, Spacing.content)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.large)
                        .fill(Color(.systemGray6))
                        .defaultShadow()
                )
                .frame(width: geo.size.width - abs(currentOffset) - (currentOffset == 0 ? 0 : Spacing.layout * 1.7))
                .offset(x: animationOffset)
                .gesture(
                    DragGesture(minimumDistance: 35)
                        .onChanged { value in
                            let horizontal = value.translation.width
                            let vertical = value.translation.height
                            
                            guard abs(horizontal) > abs(vertical) else { return }
                            
                            let direction = horizontal > 0 ? SwipeDirection.right : SwipeDirection.left
                            if swipedScheduleId != schedule.id || swipedDirection != direction {
                                onSwiped(schedule.id, direction)
                            }
                        }
                        .onEnded { value in
                            let horizontal = value.translation.width
                            let vertical = value.translation.height
                            
                            guard abs(horizontal) > abs(vertical) else {
                                onSwiped(nil, nil)
                                return
                            }
                            
                            if abs(horizontal) > maxSwipeDistance / 2 {
                                let direction = horizontal > 0 ? SwipeDirection.right : SwipeDirection.left
                                onSwiped(schedule.id, direction)
                            } else {
                                onSwiped(nil, nil)
                            }
                        },
                    including: .gesture
                )
                .simultaneousGesture(
                    TapGesture().onEnded {
                        onSwiped(nil, nil)
                    }
                )
            }
        }
        .animation(.easeInOut, value: animationOffset)
        .frame(height: 70)
    }
}
