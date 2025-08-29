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

    var asSidePanel: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.content) {
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 60, height: 5)
                .frame(maxWidth: .infinity)
                .scaleEffect(isDragging ? 1.4 : 1.0)
                .animation(.spring, value: isDragging)
                .opacity(asSidePanel ? 0 : 1)

            Text(planVM.selectedDate.dateFormat("M월 d일 E요일"))
                .font(.headline)
                .padding(.horizontal)
                .opacity(asSidePanel ? 1.0 : (isDragging ? 0.7 : 1.0))

            ScrollView {
                let upcomingIDs = planVM.highlightedUpcomingIDs(on: planVM.selectedDate)

                LazyVStack(spacing: 10) {
                    if planVM.selectedDateScheduleItems.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(planVM.selectedDateScheduleItems, id: \.self) { item in
                            ScheduleItemView(
                                schedule: item,
                                contextDate: planVM.selectedDate,
                                onToggleComplete: { schedule in
                                    Task {
                                        await planVM.toggleCompleted(for: schedule.id)
                                    }
                                },
                                isUpcomingGroup: upcomingIDs.contains(item.id)
                            )
                            .onTapGesture { selectedItem = item }
                        }
                    }
                }
                .padding()
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear
                    .frame(height: 100)
            }
            .scrollDisabled(asSidePanel ? false : (isDragging || !isSheetExpanded))
            .opacity(asSidePanel ? 1.0 : (isDragging ? 0.7 : 1.0))

            Spacer()
        }
        .padding(.top, Spacing.layout)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: asSidePanel ? 0 : 32, style: .continuous))
        .if(colorScheme == .dark && asSidePanel == false) { view in
            view.overlay(alignment: .top) {
                Rectangle()
                    .fill(Color.secondary)
                    .frame(height: 0.5)
            }
        }
        .if(colorScheme == .light && asSidePanel == false) { view in
            view.defaultShadow(color: .secondary.opacity(0.4), radius: 4, x: 0, y: 0)
        }
        .gesture(asSidePanel ? nil : dragGesture)
        .fullScreenCover(item: $selectedItem) { item in
            ManualScheduleInputView(
                mode: .edit(id: item.id),
                selectedTab: $selectedTab,
                selectedCreationType: $selectedCreationType,
                planVM: planVM
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
                if !isDragging { isDragging = true }
                currentDragOffset = value.translation.height
            }
            .onEnded { value in
                isDragging = false
                let threshold: CGFloat = 80
                if value.translation.height < -threshold {
                    withAnimation(.spring) { isSheetExpanded = true }
                } else if value.translation.height > threshold {
                    withAnimation(.spring) { isSheetExpanded = false }
                }
                currentDragOffset = 0
            }
    }
}

#Preview {
    ScheduleSheetView(
        planVM: PlanViewModel(),
        isSheetExpanded: .constant(false),
        selectedTab: .constant(.plan),
        selectedCreationType: .constant(.createByUser),
        asSidePanel: true
    )
    .frame(width: 500, height: 600)
    .padding()
}
