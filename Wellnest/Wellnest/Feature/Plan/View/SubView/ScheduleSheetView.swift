//
//  ScheduleSheetView.swift
//  Wellnest
//
//  Created by 박동언 on 8/4/25.
//

import SwiftUI

struct DayPartition {
    var allDay: [ScheduleItem] = []
    var starters: [Int: [ScheduleItem]] = [:]
    var carryOvers: [ScheduleItem] = []
}

struct ScheduleSheetView: View {
    @Environment(\.colorScheme) private var colorScheme

    @ObservedObject var planVM: PlanViewModel
    @Binding var isSheetExpanded: Bool

    @State private var currentDragOffset: CGFloat = 0
    @State private var isDragging: Bool = false

    @State private var selectedItem: ScheduleItem?
    @Binding var selectedTab: TabBarItem
    @Binding var selectedCreationType: ScheduleCreationType?

    @State private var forecastByDay: [Date: WeatherItem] = [:]
    @State private var currentWeather: WeatherItem?

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

            HStack {
                Text(planVM.selectedDate.dateFormat("M월 d일 E요일"))
                    .font(.headline)
                    .opacity(asSidePanel ? 1.0 : (isDragging ? 0.7 : 1.0))

                Spacer()

                if let currentWeather {
                    WeatherBadge(
                        item: currentWeather,
                        showCurrentOnly: Calendar.current.isDateInToday(planVM.selectedDate)
                    )
                    .transition(.opacity)
                }
            }
            .frame(height: 40)
            .padding(.horizontal)

            ScrollView(showsIndicators: false) {
                let date = planVM.selectedDate
                let items = planVM.selectedDateScheduleItems
                let upcomingIDs = planVM.highlightedUpcomingIDs(on: date)

                if items.isEmpty {
                    emptyStateView
                        .padding(.horizontal)
                        .padding(.top, Spacing.inline)
                } else {
                    let partition = buildDayPartition(for: date, items: items)
                    let sortedHours = partition.starters.keys.sorted()

                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(partition.allDay, id: \.id) { item in
                            ScheduleItemView(
                                schedule: item,
                                contextDate: nil,
                                onToggleComplete: { _ in },
                                isUpcomingGroup: false
                            )
                            .onTapGesture { selectedItem = item }
                        }


                        let zeroHourStarters = partition.starters[0] ?? []
                        if !partition.carryOvers.isEmpty || !zeroHourStarters.isEmpty {
                            HourLine(hour: 0)

                            ForEach(partition.carryOvers, id: \.id) { item in
                                ScheduleItemView(
                                    schedule: item,
                                    contextDate: date,
                                    onToggleComplete: { _ in },
                                    isUpcomingGroup: false
                                )
                                .padding(.leading, 48)
                                .onTapGesture { selectedItem = item }
                            }

                            ForEach(zeroHourStarters, id: \.id) { item in
                                ScheduleItemView(
                                    schedule: item,
                                    contextDate: date,
                                    onToggleComplete: { schedule in
                                        Task { await planVM.toggleCompleted(for: schedule.id) }
                                    },
                                    isUpcomingGroup: upcomingIDs.contains(item.id)
                                )
                                .padding(.leading, 48)
                                .onTapGesture { selectedItem = item }
                            }
                        }

                        ForEach(sortedHours.filter { $0 != 0 }, id: \.self) { hour in
                            HourLine(hour: hour)

                            ForEach(partition.starters[hour] ?? [], id: \.id) { item in
                                ScheduleItemView(
                                    schedule: item,
                                    contextDate: date,
                                    onToggleComplete: { schedule in
                                        Task { await planVM.toggleCompleted(for: schedule.id) }
                                    },
                                    isUpcomingGroup: upcomingIDs.contains(item.id)
                                )
                                .padding(.leading, 48)
                                .onTapGesture { selectedItem = item }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, Spacing.inline)
                }
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
        .task {
            let list = await WeatherCenter.shared.waitForForecast()

            currentWeather = list.first { item in
                Calendar.current.isDate(item.dt, inSameDayAs: planVM.selectedDate)
            }
        }
        .onChange(of: planVM.selectedDate) { newValue in
            Task { @MainActor in
                let list = await WeatherCenter.shared.waitForForecast()
                currentWeather = list.first { item in
                    Calendar.current.isDate(item.dt, inSameDayAs: newValue)
                }
            }
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

    private struct HourLine: View {
        let hour: Int

        var body: some View {
            HStack(spacing: 8) {
                Text(String(format: "%02d:00", hour))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 48, alignment: .leading)
                    .padding(.vertical, 2)

                Rectangle()
                    .fill(Color.secondary.opacity(0.25))
                    .frame(height: 1)
            }
            .accessibilityHidden(true)
        }
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

    private func buildDayPartition(
        for date: Date,
        items: [ScheduleItem],
        calendar: Calendar = .current
    ) -> DayPartition {
        var result = DayPartition()
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd   = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        for item in items {
            guard item.endDate > dayStart && item.startDate < dayEnd else { continue }

            if item.isAllDay || item.display(on: date).isAllDayForThatDate {
                result.allDay.append(item)
                continue
            }

            if item.startDate < dayStart {
                result.carryOvers.append(item)
            } else {
                let h = calendar.component(.hour, from: item.startDate)
                result.starters[h, default: []].append(item)
            }
        }

        result.allDay.sort { $0.title < $1.title }
        result.carryOvers.sort { $0.endDate < $1.endDate }
        for k in result.starters.keys {
            result.starters[k]?.sort { $0.startDate < $1.startDate }
        }
        return result
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
