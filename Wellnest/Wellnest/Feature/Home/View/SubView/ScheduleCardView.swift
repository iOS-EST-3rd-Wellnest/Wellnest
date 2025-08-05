//
//  ScheduleCardView.swift
//  Wellnest
//
//  Created by JuYong Lee on 8/4/25.
//
import SwiftUI

struct ScheduleCardView: View {
    @EnvironmentObject private var viewModel: ManualScheduleViewModel
    
    @State private var isDeleting = false
    @State private var deleteOffset: CGFloat = 0
    
    let schedule: ScheduleItem

    let swipedScheduleId: UUID?
    let swipedDirection: SwipeDirection?
    let onSwiped: (UUID?, SwipeDirection?) -> Void

    let maxSwipeDistance: CGFloat = 35
    
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
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                HStack {
                    if currentOffset > 0 {
                        Button {
                            print("완료: \(schedule.id)")
                        } label: {
                            Image(systemName: "checkmark")
                                .frame(width: 60, height: 70)
                                .foregroundStyle(.black)
                        }
                        .background(
                            Capsule()
                                .fill(Color(.systemGray6))
                                .padding(.horizontal, Spacing.content)
                        )
                        
                        Spacer()
                    } else if currentOffset < 0 {
                        Spacer()
                        
                        Button {
                            withAnimation(.easeIn(duration: 0.3)) {
                                isDeleting = true
                                deleteOffset = -geo.size.width
                            }
                            
                            //Task {
                            //    try? await Task.sleep(nanoseconds: 300_000_000)
                            //    await viewModel.deleteSchedule(schedule)
                            //}
                            
                        } label: {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.white)
                                .frame(width: 60, height: 70)
                        }
                        .background(
                            Capsule()
                                .fill(.red)
                                .padding(.horizontal, Spacing.content)
                        )
                    }
                }
                
                //            ScheduleItemView(schedule: schedule)
                VStack(alignment: .leading, spacing: Spacing.inline) {
                    HStack {
                        Image(systemName: "clock.fill")
                        
                        Text("\(schedule.startDate.formattedTime) ~ \(schedule.endDate.formattedTime)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        
                        Rectangle()
                            .fill(.gray)
                            .frame(width: 2, height: 15)
                        
                        Spacer()
                    }
                    
                    Text(schedule.title)
                        .font(.caption)
                        .bold()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.large)
                        .fill(Color(.systemGray6))
                        .defaultShadow()
                )
                .frame(width: geo.size.width - abs(currentOffset) - (currentOffset == 0 ? 0 : 32))
                .offset(x: isDeleting ? deleteOffset : currentOffset)
                .gesture(
                    DragGesture(minimumDistance: 30)
                        .onChanged { value in
                            let horizontal = value.translation.width
                            let vertical = value.translation.height
                            
                            guard abs(horizontal) > abs(vertical) else { return }
                            
                            let direction: SwipeDirection = horizontal > 0 ? .right : .left
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
                                let direction: SwipeDirection = horizontal > 0 ? .right : .left
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
        .animation(.easeInOut, value: isDeleting ? deleteOffset : currentOffset)
        .frame(height: 70)
    }
}

enum SwipeDirection {
    case left, right
}
