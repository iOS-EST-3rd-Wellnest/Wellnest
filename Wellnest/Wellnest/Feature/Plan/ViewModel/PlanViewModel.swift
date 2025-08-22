//
//  PlanViewModel.swift
//  Wellnest
//
//  Created by 박동언 on 8/4/25.
//

import Foundation
import SwiftUI
import EventKit

final class PlanViewModel: ObservableObject {
//    @Published var selectedDate: Date
    @Published var selectedDate: Date {
        didSet {
            Task { @MainActor in
                coalescedRecalc()
            }
        }
    }
    @Published var displayedMonth: Date {
        didSet {
            updateDisplayedMonth()
            expandMonthsIfNeeded(from: displayedMonth)
        }
    }
    @Published var calendarDates: [Date]
    @Published var months: [Date]

	@Published var scheduleStore = ScheduleStore()
    
    @Published private(set) var iOSCalendarItems: [ScheduleItem] = []
    @Published private(set) var mergedItems: [ScheduleItem] = []
    @Published private(set) var iOSCalendarMonthCache: [Date: [Date: [ScheduleItem]]] = [:]
    
    private var storeChangeObserver: NSObjectProtocol?
    private var coreDataObserver: NSObjectProtocol?
    private var monthPreloadTask: Task<Void, Never>?
    private let calendar = Calendar.current
//    private var isCalendarEnabled: Bool { UserDefaultsManager.shared.isCalendarEnabled }

    init(selectedDate: Date = Date()) {
        let calendar = Calendar.current
        let normalized = selectedDate.startOfDay

        self.selectedDate = normalized
        self.displayedMonth = normalized.startOfMonth
        self.calendarDates = normalized.filledDatesOfMonth()
        self.months = (-12...12).compactMap {
            calendar.date(byAdding: .month, value: $0, to: normalized.startOfMonth)
        }
    }
    
    var iOSCalendarbyDay: [Date: [ScheduleItem]] {
        iOSCalendarMonthCache[displayedMonth.startOfMonth] ?? [:]
    }

    var selectedDateScheduleItems: [ScheduleItem] {
        scheduleStore.scheduleItems(for: selectedDate)
    }

    func hasSchedule(for date: Date) -> Bool {
        scheduleStore.hasSchedule(for: date)
    }
    
    deinit {
        if let obs = storeChangeObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }
}

extension PlanViewModel {
    func calenderHeight(
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

    private func updateDisplayedMonth() {
        calendarDates = displayedMonth.filledDatesOfMonth()

        if !calendar.isDate(selectedDate, equalTo: displayedMonth, toGranularity: .month) {
             selectedDate = displayedMonth
         }
    }

    private func expandMonthsIfNeeded(from month: Date) {
        guard let currentIndex = months.firstIndex(of: month) else { return }

        if currentIndex <= 3 {
            guard let first = months.first else { return }
            let prepend = (-9..<0).compactMap {
                calendar.date(byAdding: .month, value: $0, to: first)
            }
            months.insert(contentsOf: prepend, at: 0)
        }

        if currentIndex >= months.count - 4 {
            guard let last = months.last else { return }
            let append = (1...9).compactMap {
                calendar.date(byAdding: .month, value: $0, to: last)
            }
            months.append(contentsOf: append)
        }
    }

    func select(date: Date) {
        let normalized = date.startOfDay
        selectedDate = normalized

        if !Calendar.current.isDate(normalized, equalTo: displayedMonth, toGranularity: .month) {
            displayedMonth = normalized.startOfMonth
            calendarDates = displayedMonth.filledDatesOfMonth()
        }
        
        Task {
            await reloadSelectedDate()
        }
    }
    
    @MainActor
    func onAppear() async {
//        if isCalendarEnabled {
            startObservingCalendar()
//        }
//        startObservingCoreData()
        Task { await reloadSelectedDate() }
        
    }
    
    @MainActor
    func reloadSelectedDate() async {
        let day = Calendar.current.startOfDay(for: selectedDate)
//        guard isCalendarEnabled else {
//            withAnimation(.easeInOut) {
//                self.iOSCalendarItems = []
//                var bucket = iOSCalendarMonthCache[day.startOfMonth] ?? [:]
//                bucket[day] = []
//                iOSCalendarMonthCache[day.startOfMonth] = bucket
//            }
//            recalcMergedItems(for: day)
//            return
//        }
            do {
                let store = EKEventStore()
                try await CalendarManager.shared.ensureAccess()

                let events = CalendarManager.shared.fetchEvent(for: day, store: store, calendars: nil)
                let items  = events.map { CalendarManager.shared.mapToScheduleItem($0) }
                self.iOSCalendarItems = items

                // 월 캐시도 선택 날짜만 보강
                let monthStart = day.startOfMonth
                var bucket = iOSCalendarMonthCache[monthStart] ?? [:]
                bucket[day] = items
                iOSCalendarMonthCache[monthStart] = bucket

            } catch {
                print("캘린더 일정 불러오기 실패:", error)
                self.iOSCalendarItems = []
                // 실패해도 캐시는 비워 둠 (옵션)
            }

            // ✅ 병합은 한 곳으로: 항상 dedupe가 들어간 경로로만 갱신
            coalescedRecalc()
    }
    
    @MainActor
    func preloadMonth(using store: EKEventStore, monthStart: Date, calendars: [EKCalendar]? = nil) async {
//        guard isCalendarEnabled else { return }
        // 이미 캐시되어 있으면 스킵
        let cal = Calendar.current
            let nextMonthStart = cal.date(byAdding: .month, value: 1, to: monthStart)!

            // 기존 캐시가 있어도 가져와서 '비어 있는 날짜'만 채운다
            var bucket = iOSCalendarMonthCache[monthStart] ?? [:]
            var didChange = false

            var cur = monthStart
            while cur < nextMonthStart {
                let dayStart = cal.startOfDay(for: cur)

                // 이미 채워진 날은 건너뛰기
                if bucket[dayStart] == nil {
                    let evs = CalendarManager.shared.fetchEvent(for: dayStart, store: store, calendars: calendars)
                    if !evs.isEmpty {
                        let items = evs.map { CalendarManager.shared.mapToScheduleItem($0) }
                        bucket[dayStart] = items
                        didChange = true
                    } else {
                        // 이벤트가 없어도 빈 배열로 채워 두면, 다음 프리패치 때 중복 fetch 방지
                        bucket[dayStart] = []
                        didChange = true
                    }
                }

                cur = cal.date(byAdding: .day, value: 1, to: dayStart)!
            }

            if didChange {
                iOSCalendarMonthCache[monthStart] = bucket
                finishPreload(monthStart: monthStart, bucket: bucket)
            }
    }
    
    @MainActor
    func preloadCurrentAndNeighbors() {
//        guard isCalendarEnabled else { return }
        
        monthPreloadTask?.cancel()
        monthPreloadTask = Task {
            // 빠른 스와이프 방지
            try? await Task.sleep(for: .milliseconds(120))
            
            let store = EKEventStore()
            // Full Access (iOS17+)
            do {
                if #available(iOS 17, *) {
                    guard try await store.requestFullAccessToEvents() else { return }
                } else {
                    guard try await store.requestAccess(to: .event) else { return }
                }
            } catch { return }
            
            let cal = Calendar.current
            let cur = displayedMonth.startOfMonth
            let prev = cal.date(byAdding: .month, value: -1, to: cur)!.startOfMonth
            let next = cal.date(byAdding: .month, value:  1, to: cur)!.startOfMonth
            
            // 순차 or 동시 프리패치 (동시가 더 빠름)
            await withTaskGroup(of: Void.self) { group in
                [prev, cur, next].forEach { month in
                    group.addTask { await self.preloadMonth(using: store, monthStart: month, calendars: nil) }
                }
            }
            
            recalcMergedItems(for: selectedDate)
        }
    }
    
    private func dayKey(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
    
    /// iOS 월 캐시 + 앱 일정 → mergedItems 갱신 (오늘)
    @MainActor
    func refreshHomeTodayFromCache() {
        let today = dayKey(Date())
        let monthStart = today.startOfMonth
        
        let app = scheduleStore.scheduleItems(for: today)
        let ios = iOSCalendarMonthCache[monthStart]?[today] ?? []
        
        mergedItems = (app + ios)
            .uniqued { ($0.eventIdentifier ?? "") + "|" + $0.id.uuidString }
            .sorted { $0.startDate < $1.startDate }
        
        Task {
            recalcMergedItems(for: selectedDate)
        }
    }
    
    /// 월 캐시가 아직 없으면 오늘만 즉시 fetch 해서 보강
    @MainActor
    func refreshHomeTodayWithFallback() async {
        let today = dayKey(Date())
        let monthStart = today.startOfMonth
        
        if iOSCalendarMonthCache[monthStart] != nil {
            refreshHomeTodayFromCache()
            return
        }
        
        // 월 캐시가 없으면 오늘만 바로 읽어서 채움
        do {
            let store = EKEventStore()
            if #available(iOS 17, *) {
                _ = try await store.requestFullAccessToEvents()
            } else {
                _ = try await store.requestAccess(to: .event)
            }
            
            let evs = CalendarManager.shared.fetchEvent(for: today, store: store, calendars: nil)
            let items = evs.map { CalendarManager.shared.mapToScheduleItem($0) }
            
            var monthBucket = iOSCalendarMonthCache[monthStart] ?? [:]
            monthBucket[today] = items
            iOSCalendarMonthCache[monthStart] = monthBucket
            
            refreshHomeTodayFromCache()
        } catch {
            // 실패해도 앱 일정만으로 표시
            refreshHomeTodayFromCache()
        }
    }
    
    /// iOS 캘린더 변경 시 홈 목록도 갱신
    @MainActor
    func startObservingCalendarForHome() {
        NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged, object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task {
                // 월 캐시 프리패치(현재/이전/다음 달) 후 오늘 갱신
                await self.preloadCurrentAndNeighbors()
                await self.refreshHomeTodayFromCache()
            }
        }
    }
    
    /// 변경된 일정이 있는지 확인
    @MainActor
    private func startObservingCalendar() {
        guard storeChangeObserver == nil else { return }
        storeChangeObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.reloadSelectedDate()
            }
        }
    }
    
    @MainActor
    func finishPreload(monthStart: Date, bucket: [Date:[ScheduleItem]]) {
        iOSCalendarMonthCache[monthStart] = bucket
        // 홈: 오늘이 이 월에 속하면 즉시 반영
        if Date().startOfMonth == monthStart {
            refreshHomeTodayFromCache()
        }
        coalescedRecalc()
    }
    
    @MainActor
    func recalcMergedItems(for date: Date) {
        let day = dayKey(date)                 // 0시 기준 정규화
        let monthStart = day.startOfMonth
        
        // 1) 앱 일정 (Core Data 기반; ScheduleStore에서 해당 날짜 버킷)
        let app = scheduleStore.scheduleItems(for: day)
        
        // 2) iOS 캘린더 일정 (가능하면 월 캐시 사용, 없으면 선택된 날짜에 한해 즉시 로드된 리스트 활용)
        let ios: [ScheduleItem]
        if let cached = iOSCalendarMonthCache[monthStart]?[day] {
            ios = cached
        } else if Calendar.current.isDate(day, inSameDayAs: selectedDate) {
            // selectedDate에 대해 reloadSelectedDate()가 만든 iOS 목록
            ios = iOSCalendarItems
        } else {
            ios = []
        }
        
        // 3) 합치기: 중복 제거 + 종일 우선 → 시작시간 순 정렬
        mergedItems = (app + ios)
            .uniqued { canonicalKey($0) }
            .sorted { a, b in
                if a.isAllDay != b.isAllDay { return a.isAllDay && !b.isAllDay }
                return a.startDate < b.startDate
            }
    }
    
    private func canonicalKey(_ item: ScheduleItem) -> String {
        if let ek = item.eventIdentifier, !ek.isEmpty {
            return "ek:\(ek)" // 동일 EK 이벤트는 무조건 1건으로
        }
        // EK id가 없으면 시간/제목 기반 보수적 dedupe
        func roundMin(_ d: Date) -> Int { Int(d.timeIntervalSince1970 / 60.0) }
        return "local:\(item.title.lowercased())|\(roundMin(item.startDate))|\(roundMin(item.endDate))|\(item.isAllDay)"
        
    }

    /// (app + ios) 순서를 유지해 첫 항목을 살려 dedupe
     func dedupeByCanonicalKey(_ items: [ScheduleItem]) -> [ScheduleItem] {
        var seen = Set<String>()
        var out: [ScheduleItem] = []
        out.reserveCapacity(items.count)
        for item in items {
            let key = canonicalKey(item)
            if seen.insert(key).inserted {
                out.append(item)
            }
        }
        return out
    }
    
    @MainActor
    func purgeIOSCache(for day: Date, eventIdentifier: String?) {
        guard let ek = eventIdentifier, !ek.isEmpty else { return }
        let month = day.startOfMonth
        if var bucket = iOSCalendarMonthCache[month] {
            let dayKey = day.startOfDay
            if var arr = bucket[dayKey] {
                arr.removeAll { $0.eventIdentifier == ek }
                bucket[dayKey] = arr
                iOSCalendarMonthCache[month] = bucket
            }
        }
        // 리스트 재계산 (dedupe 포함)
        coalescedRecalc()
    }
    
    @MainActor
    func coalescedRecalc() {
        // 직전 예약 작업이 있으면 취소하고, 마지막 한 번만 실행
        monthPreloadTask?.cancel()
        monthPreloadTask = Task { [weak self] in
            guard let self else { return }
            // 아주 짧게 모아서 한 번만 반영 (깜빡임 방지)
            try? await Task.sleep(for: .milliseconds(50))
            
            withAnimation(.none) {
                self.recalcMergedItems(for: self.selectedDate)
            }
        }
    }
}

private extension Array {
    func uniqued<Key: Hashable>(_ key: (Element) -> Key) -> [Element] {
        var seen = Set<Key>()
        return filter { seen.insert(key($0)).inserted }
    }
}
