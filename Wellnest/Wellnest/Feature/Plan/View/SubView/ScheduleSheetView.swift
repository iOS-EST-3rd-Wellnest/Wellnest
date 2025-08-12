//
//  ScheduleSheetView.swift
//  Wellnest
//
//  Created by 박동언 on 8/4/25.
//

import SwiftUI

struct ScheduleSheetView: View {
    @ObservedObject var planVM: PlanViewModel
    @Binding var isSheetExpanded: Bool

    @State private var currentDragOffset: CGFloat = 0
    @State private var isDragging: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.content) {
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 60, height: 5)
                .frame(maxWidth: .infinity)
                .scaleEffect(isDragging ? 1.2 : 1.0)
//                .animation(.easeInOut, value: isDragging)

            Text(planVM.selectedDate.dateFormat("M월 d일 E요일"))
                .font(.headline)
                .padding(.horizontal)

            ScrollView {
                LazyVStack(spacing: Spacing.layout) {
                    scheduleCard(time: "10:00 - 11:20 AM", title: "아침 식사", color: .yellow)
                    scheduleCard(time: "10:00 - 1:20 PM", title: "운동하기", color: .pink)
                    scheduleCard(time: "10:00 - 11:20 AM", title: "아침 식사", color: .yellow)
                    scheduleCard(time: "10:00 - 1:20 PM", title: "운동하기", color: .pink)
                    scheduleCard(time: "10:00 - 11:20 AM", title: "아침 식사", color: .yellow)
                    scheduleCard(time: "10:00 - 1:20 PM", title: "운동하기", color: .pink)
                }
                .padding(.top, Spacing.content)
                .padding(.horizontal)
            }
            .scrollDisabled(isDragging || !isSheetExpanded)

            Spacer()
        }
        .padding(.top, Spacing.layout)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .defaultShadow()
        .gesture(dragGesture)
        //        .animation(.spring, value: isSheetExpanded)
//        .animation(.spring, value: currentDragOffset)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                }
                currentDragOffset = value.translation.height
            }
            .onEnded { value in
                isDragging = false

                let threshold: CGFloat = 100

                if value.translation.height < -threshold {
                    isSheetExpanded = true
                } else if value.translation.height > threshold {
                    isSheetExpanded = false
                }

                currentDragOffset = 0

            }
    }

    func scheduleCard(time: String, title: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.content) {
            Text(time)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(title)
                .bold()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                .fill(color)
                .defaultShadow()
        }
    }
}

#Preview {
    ScheduleSheetView(planVM: PlanViewModel(), isSheetExpanded: .constant(false))
}
