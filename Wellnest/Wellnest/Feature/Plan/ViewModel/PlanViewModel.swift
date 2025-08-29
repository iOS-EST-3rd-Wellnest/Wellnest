//
//  PlanViewModel.swift
//  Wellnest
//
//  Created by 박동언 on 8/4/25.
//

import Foundation
import SwiftUI
import CoreData
import Combine

@MainActor
final class PlanViewModel: ObservableObject {


    @Published var selectedDate: Date
    @Published private(set) var anchorMonth: Date
    @Published private(set) var visibleMonth: Date
    @Published private(set) var jumpToken: Int = 0

    @Published var scheduleStore: ScheduleStore

    private var cancellables: Set<AnyCancellable> = []
    private let prefetchRadius = 3
    private let pageRange = -3...3
    private let calendar = Calendar.current


    init(selectedDate: Date = Date()) {
        let normalized = selectedDate.startOfDay
        let month = normalized.startOfMonth

        self.selectedDate = normalized
        self.anchorMonth  = month
        self.visibleMonth = month
        self.scheduleStore = ScheduleStore(context: CoreDataService.shared.context)

        bindScheduleStoreChangeForwarding()

        Task { await prefetchMonthsAround(anchorMonth) }
    }

    deinit {
        cancellables.removeAll()
    }
}

extension PlanViewModel {
    var selectedDateScheduleItems: [ScheduleItem] {
        scheduleStore.items(on: selectedDate)
    }

    func hasSchedule(for date: Date) -> Bool {
        scheduleStore.hasItems(on: date)
    }

    func items(for day: Date) -> [ScheduleItem] {
        scheduleStore.items(on: day)
    }

    func selectDate(_ date: Date) {
        selectedDate = date.startOfDay
    }

    func combine(date: Date, time: Date = Date()) -> Date? {
        let d = calendar.dateComponents([.year, .month, .day], from: date)
        let t = calendar.dateComponents([.hour, .minute, .second], from: time)
        var merged = DateComponents()
        merged.year = d.year; merged.month = d.month; merged.day = d.day
        merged.hour = t.hour; merged.minute = t.minute; merged.second = t.second
        return calendar.date(from: merged)
    }

    func updateVisibleMonth(_ month: Date) {
        let m = month.startOfMonth
        visibleMonth = m
        selectedDate = m
    }

//    func updateVisibleMonthOnly(_ month: Date) {
//        visibleMonth = month.startOfMonth
//    }
    func toggleCompleted(for id: UUID) async {
        await scheduleStore.toggleCompleted(for: id)
    }
}

extension PlanViewModel {
    func generatePageMonths(center: Date? = nil) -> [Date] {
        let baseMonth = (center ?? visibleMonth).startOfMonth
        return pageRange.map { addMonths(to: baseMonth, count: $0) }
    }

    func recenterVisibleMonth(to month: Date) {
        let monthStart = month.startOfMonth
        visibleMonth = monthStart
        anchorMonth  = monthStart
        selectedDate = monthStart
        Task { await prefetchMonthsAround(monthStart) }
    }

    func jumpToDate(_ date: Date) {
        let monthStart = date.startOfMonth
        visibleMonth = monthStart
        anchorMonth  = monthStart
        selectedDate = date.startOfDay
        Task { await prefetchMonthsAround(monthStart) }
        jumpToken &+= 1
    }

    func stagePrefetch(direction: Int) {
        let nextAnchorMonth = addMonths(to: visibleMonth, count: direction)
        guard nextAnchorMonth != anchorMonth else { return }
        anchorMonth = nextAnchorMonth
        Task { await prefetchMonthsAround(nextAnchorMonth) }
    }
}

extension PlanViewModel {
    private func prefetchMonthsAround(_ month: Date) async {
        for offset in -prefetchRadius...prefetchRadius {
            let targetMonth = addMonths(to: month, count: offset)
            await scheduleStore.ensureMonthLoaded(targetMonth)
        }
    }

    func addMonths(to date: Date, count: Int) -> Date {
        calendar.date(byAdding: .month, value: count, to: date.startOfMonth)!.startOfMonth
    }
}

extension PlanViewModel {
    private func bindScheduleStoreChangeForwarding() {
        scheduleStore.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }
}


