//
//  ScheduleSheetView.swift
//  Wellnest
//
//  Created by 박동언 on 8/4/25.
//

import SwiftUI

struct ScheduleSheetView: View {
    @Environment(\.colorScheme) private var colorScheme

    @ObservedObject var planVM: PlanViewModel
    @Binding var isSheetExpanded: Bool

    @State private var currentDragOffset: CGFloat = 0
    @State private var isDragging: Bool = false

    @State private var selectedItem: ScheduleItem?
    @Binding var selectedTab: TabBarItem
    @Binding var selectedCreationType: ScheduleCreationType?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.content) {
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 60, height: 5)
                .frame(maxWidth: .infinity)
                .scaleEffect(isDragging ? 1.4 : 1.0)
                .animation(.spring, value: isDragging)

            Text(planVM.selectedDate.dateFormat("M월 d일 E요일"))
                .font(.headline)
                .padding(.horizontal)
                .opacity(isDragging ? 0.7 : 1.0)

            ScrollView {
                LazyVStack(spacing: 10) {
                    if planVM.selectedDateScheduleItems.isEmpty {
                         emptyStateView
                     } else {
                         ForEach(planVM.selectedDateScheduleItems.indices, id: \.self) { idx in
                             let item = planVM.selectedDateScheduleItems[idx]

                             ScheduleItemView(schedule: item, contextDate: planVM.selectedDate)
                                 .onTapGesture {
                                     selectedItem = item
                                 }
                         }
                     }
                }
                .padding()
            }
            .scrollDisabled(isDragging || !isSheetExpanded)
            .opacity(isDragging ? 0.7 : 1.0)

            Spacer()
        }
        .padding(.top, Spacing.layout)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .if(colorScheme == .dark) { view in
            view.overlay(alignment: .top) {
                Rectangle()
                    .fill(Color.secondary)
                    .frame(height: 0.5)
            }
        }
        .if(colorScheme == .light) { view in
            view.defaultShadow(color: .secondary.opacity(0.4), radius: 4, x: 0, y: 0)
        }
        .gesture(dragGesture)
        .fullScreenCover(item: $selectedItem) { item in
            ManualScheduleInputView(
                mode: .edit(id: item.id),
                selectedTab: $selectedTab,
                selectedCreationType: $selectedCreationType, planVM: planVM
            )
        }
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: Spacing.layout) {
            Image(systemName: "calendar.badge.plus")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text("예정된 일정이 없습니다.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.layout * 2)
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

                let threshold: CGFloat = 80

                if value.translation.height < -threshold {
                    withAnimation(.spring) {
                        isSheetExpanded = true
                    }
                } else if value.translation.height > threshold {
                    withAnimation(.spring) {
                        isSheetExpanded = false
                    }
                }

                currentDragOffset = 0
            }
    }
}

#Preview {
    ScheduleSheetView(planVM: PlanViewModel(), isSheetExpanded: .constant(false), selectedTab: .constant(.plan), selectedCreationType: .constant(.createByUser))
}
