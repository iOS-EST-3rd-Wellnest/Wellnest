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

    struct CachedMonthData {
        let monthStart: Date
        let dates: [Date]
    }
    @Published private(set) var monthDataCache: [Date: CachedMonthData] = [:]
    private var backgroundLoaders: [Date: Task<CachedMonthData, Never>] = [:]

    private let prefetchRadius = 3
    private let pageRange = -3...3

    private let calendar = Calendar.current

    init(selectedDate: Date = Date(), context: NSManagedObjectContext = CoreDataStack.shared.container.viewContext) {
        let normalized = selectedDate.startOfDay
        let normalizedMonth = normalized.startOfMonth

        self.scheduleStore = ScheduleStore(context: context)

        self.selectedDate = normalized
        self.anchorMonth =	normalizedMonth
        self.visibleMonth = normalizedMonth

        bindScheduleStoreChangeForwarding()

        prefetchMonthsAroundAnchor()
        trimCacheAroundMonth(normalizedMonth)
    }

    deinit {
        for (_, task) in backgroundLoaders { task.cancel() }

        cancellables.removeAll()
    }
}

extension PlanViewModel {
    var selectedDateScheduleItems: [ScheduleItem] {
        scheduleStore.scheduleItems(for: selectedDate)
    }

    func hasSchedule(for date: Date) -> Bool {
        scheduleStore.hasSchedule(for: date)
    }

    func selectDate(_ date: Date) {
        selectedDate = date.startOfDay
    }

    func updateVisibleMonth(_ month: Date) {
        let startOfMonth = month.startOfMonth
        visibleMonth = startOfMonth
        selectedDate = startOfMonth
    }

    func updateVisibleMonthOnly(_ month: Date) {
        visibleMonth = month.startOfMonth
    }
}

extension PlanViewModel {
    func generatePageMonths(center: Date? = nil) -> [Date] {
         let baseMonth = (center ?? visibleMonth).startOfMonth
         return pageRange.map { offset in
             addMonths(to: baseMonth, count: offset)
         }
     }

    func recenterVisibleMonth(to month: Date) {
        let startOfMonth = month.startOfMonth
        visibleMonth = startOfMonth
        anchorMonth = startOfMonth
        selectedDate = startOfMonth
        
        prefetchMonthsAroundAnchor()
        trimCacheAroundMonth(anchorMonth)
    }

    func jumpToDate(_ date: Date) {
        let startOfMonth = date.startOfMonth
        visibleMonth = startOfMonth
        anchorMonth  = startOfMonth
        selectedDate = date.startOfDay

        prefetchMonthsAroundAnchor()
        trimCacheAroundMonth(anchorMonth)
        jumpToken &+= 1
    }

    func stagePrefetch(direction: Int) {
        let nextAnchorMonth = addMonths(to: visibleMonth, count: direction)
        guard nextAnchorMonth != anchorMonth else { return }

        anchorMonth = nextAnchorMonth
        prefetchMonthsAroundAnchor()
    }
}

extension PlanViewModel {
    private func prefetchMonthsAroundAnchor() {
        for offset in -prefetchRadius...prefetchRadius {
            let targetMonth = addMonths(to: anchorMonth, count: offset)
            ensureMonthDataInCache(targetMonth)
        }
    }

    private func ensureMonthDataInCache(_ month: Date) {
        let monthKey = month.startOfMonth
        if monthDataCache[monthKey] != nil { return }
        if backgroundLoaders[monthKey] != nil { return }

        backgroundLoaders[monthKey] = Task(priority: .utility) { [weak self] in
            guard let self else { return CachedMonthData(monthStart: monthKey, dates: []) }

            let result = await MonthDataLoader.load(month: monthKey, store: self.scheduleStore)

            await MainActor.run {
                self.monthDataCache[monthKey] = CachedMonthData(monthStart: monthKey, dates: result)
                self.backgroundLoaders[monthKey] = nil
            }

            return self.monthDataCache[monthKey] ?? CachedMonthData(monthStart: monthKey, dates: [])
        }
    }

    private func trimCacheAroundMonth(_ centerMonth: Date) {
        let monthsToKeep = Set((-prefetchRadius...prefetchRadius).map {
            addMonths(to: centerMonth, count: $0)
        })

        let cachedMonthsToRemove = monthDataCache.keys.filter {
            !monthsToKeep.contains($0)
        }
        cachedMonthsToRemove.forEach { monthDataCache.removeValue(forKey: $0) }

        let loadersToCancel = backgroundLoaders.keys.filter {
            !monthsToKeep.contains($0)
        }
        loadersToCancel.forEach { monthKey in
            backgroundLoaders[monthKey]?.cancel()
            backgroundLoaders[monthKey] = nil
        }
    }

    func addMonths(to date: Date, count: Int) -> Date {
         calendar.date(byAdding: .month, value: count, to: date.startOfMonth)!.startOfMonth
     }
}
extension PlanViewModel {
    private func rebindScheduleStoreIfNeeded() {
        cancellables.removeAll()
        bindScheduleStoreChangeForwarding()
    }

    private func bindScheduleStoreChangeForwarding() {
        scheduleStore.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}

extension PlanViewModel {
    func calendarHeight(
        width: CGFloat = UIScreen.main.bounds.width,
        rows: Int,
        columns: Int = 7,
        spacing: CGFloat = 4,
        padding: CGFloat = 16
    ) -> CGFloat {
        let screenWidth = width - padding * 2

        let totalSpacingWidth = spacing * CGFloat(columns - 1)
        let totalSpacingHeight = spacing * CGFloat(rows - 1)

        let itemWidth = (screenWidth - totalSpacingWidth) / CGFloat(columns)

        let itemHeight: CGFloat = {
            if rows == 1 {
                itemWidth - spacing * 2
            } else {
                itemWidth * CGFloat(rows) + totalSpacingHeight
            }
        }()

        return itemHeight
    }
}

actor MonthDataLoader {
    static func load(month: Date, store: ScheduleStore) async -> [Date] {
        let dates = month.filledDatesOfMonth()
        _ = await store.fetchSchedules(in: month)
        return dates
    }
}
