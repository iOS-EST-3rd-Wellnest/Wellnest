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

    @Published var scheduleStore: ServiceScheduleStore

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

    init(selectedDate: Date = Date(), service: CoreDataService = .shared) {
        let normalized = selectedDate.startOfDay
        let normalizedMonth = normalized.startOfMonth

//        self.scheduleStore = ScheduleStore(context: context)
        self.scheduleStore = ServiceScheduleStore(service: service)

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
    static func load(month: Date, store: ServiceScheduleStore) async -> [Date] {
        let dates = month.filledDatesOfMonth()
        _ = await store.fetchSchedules(in: month)
        return dates
    }
}

@MainActor
final class ServiceScheduleStore: ObservableObject {
    private let service: CoreDataService
    private let calendar = Calendar.current

    // 메모리 캐시 (필요/선호에 맞게 조정 가능)
    @Published private(set) var dayCache: [Date: [ScheduleItem]] = [:]
    @Published private(set) var monthPrefetchMark: Set<Date> = []

    init(service: CoreDataService = .shared) {
        self.service = service
    }

    // MARK: - Public API (PlanViewModel에서 사용)

    func scheduleItems(for date: Date) -> [ScheduleItem] {
        let key = date.startOfDay
        if let cached = dayCache[key] {
            return cached
        }
        let loaded = loadDay(date: key)
        dayCache[key] = loaded
        return loaded
    }

    func hasSchedule(for date: Date) -> Bool {
        !scheduleItems(for: date).isEmpty
    }

    /// 월간 프리페치(PlanViewModel.MonthDataLoader에서 호출)
    @discardableResult
    func fetchSchedules(in month: Date) async -> [ScheduleItem] {
        let start = month.startOfMonth
        let end   = calendar.date(byAdding: .month, value: 1, to: start)!.startOfMonth

        let items = loadRange(start: start, end: end)
        // 일자별로 캐시에 저장
        let grouped = Dictionary(grouping: items, by: { $0.startDate.startOfDay })
        for (k, v) in grouped {
            dayCache[k] = v.sorted(by: scheduleSort)
        }
        monthPrefetchMark.insert(start)
        return items
    }

    // MARK: - CoreData Query

    private func loadDay(date: Date) -> [ScheduleItem] {
        let start = date.startOfDay
        let end = calendar.date(byAdding: .day, value: 1, to: start)!

        return loadRange(start: start, end: end)
    }

    /// [start, end) 구간의 스케줄 로드
    private func loadRange(start: Date, end: Date) -> [ScheduleItem] {
        let p = NSPredicate(format: "endDate != nil AND endDate > %@ AND startDate < %@", start as CVarArg, end as CVarArg)
        let sort = [
            NSSortDescriptor(key: "startDate", ascending: true),
            NSSortDescriptor(key: "endDate", ascending: true)
        ]

        do {
            let entities: [ScheduleEntity] = try service.fetch(ScheduleEntity.self, predicate: p, sortDescriptors: sort)
            return entities.compactMap(mapEntityToItem(_:)).sorted(by: scheduleSort)
        } catch {
            print("loadRange error: \(error)")
            return []
        }
    }

    // MARK: - Mapper & Sorter

    /// ScheduleEntity → ScheduleItem 매핑
    /// 프로젝트의 실제 ScheduleItem 초기화 규칙에 맞게 조정하세요.
    private func mapEntityToItem(_ e: ScheduleEntity) -> ScheduleItem? {
        // 예시 매핑 (필드명/생성자에 맞춰 수정)
        ScheduleItem(
            id: e.id ?? UUID(),
            title: e.title ?? "",
            startDate: e.startDate ?? Date(),
            endDate: e.endDate ?? Date(),
            createdAt: e.createdAt ?? Date(),
            updatedAt: e.updatedAt ?? Date(),
            backgroundColor: e.backgroundColor ?? "wellnestBlue",
            isAllDay: e.isAllDay?.boolValue ?? false,
            repeatRule: e.repeatRule,
            hasRepeatEndDate: e.hasRepeatEndDate,
            repeatEndDate: e.repeatEndDate,
            isCompleted: (e.isCompleted != nil),
            eventIdentifier: e.eventIdentifier,
            location: e.location,
            alarm: e.alarm
        )
    }

    private func scheduleSort(_ a: ScheduleItem, _ b: ScheduleItem) -> Bool {
        if a.startDate != b.startDate { return a.startDate < b.startDate }
        if a.endDate != b.endDate { return a.endDate < b.endDate }
        return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
    }
}
