//
//  ScheduleProgressViewModel.swift
//  Wellnest
//
//  Created by Jusung Kye on 8/27/25.
//

import Foundation
import CoreData

enum ScheduleProgressType: CaseIterable, Identifiable {
    var id: Self { self }
    
    case today
    case weekly
    case monthly
}

final class ScheduleProgressViewModel: NSObject, ObservableObject {
    var todayItems: [ScheduleEntity] = [] {
        didSet { recomputeTodayStats() }
    }
    
    var weeklyItems: [ScheduleEntity] = [] {
        didSet { recomputeWeeklyStats() }
    }
    
    var monthlyItems: [ScheduleEntity] = [] {
        didSet { recomputeMonthlyStats() }
    }

    @Published private(set) var todayScheduleCount: Int = 0
    @Published private(set) var todayCompletedCount: Int = 0
    @Published private(set) var todayRemainCount: Int = 0
    @Published private(set) var todayCompletionRate: Double = 0.0
    
    @Published private(set) var weeklyScheduleCount: Int = 0
    @Published private(set) var weeklyCompletedCount: Int = 0
    @Published private(set) var weeklyRemainCount: Int = 0
    @Published private(set) var weeklyCompletionRate: Double = 0.0
    
    @Published private(set) var monthlyScheduleCount: Int = 0
    @Published private(set) var monthlyCompletedCount: Int = 0
    @Published private(set) var monthlyRemainCount: Int = 0
    @Published private(set) var monthlyCompletionRate: Double = 0.0

    private let context: NSManagedObjectContext
    private let fetchResultTodayController: NSFetchedResultsController<ScheduleEntity>
    private let fetchResultWeeklyController: NSFetchedResultsController<ScheduleEntity>
    private let fetchResultMonthlyController: NSFetchedResultsController<ScheduleEntity>
    private var dayChangeObserver: NSObjectProtocol?
    
    private static  let predicateFormat = "startDate < %@ AND endDate >= %@"

    override init() {
        self.context = CoreDataService.shared.context
        
        let request: NSFetchRequest<ScheduleEntity> = ScheduleEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]
        request.predicate = Self.todayPredicate()

        self.fetchResultTodayController = NSFetchedResultsController(fetchRequest: request,
                                                                managedObjectContext: context,
                                                                sectionNameKeyPath: nil,
                                                                cacheName: nil)
        
        let weeklyRequest: NSFetchRequest<ScheduleEntity> = ScheduleEntity.fetchRequest()
        weeklyRequest.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        weeklyRequest.predicate = Self.weeklyPredicate()
        
        self.fetchResultWeeklyController = NSFetchedResultsController(fetchRequest: weeklyRequest,
                                                                managedObjectContext: context,
                                                                sectionNameKeyPath: nil,
                                                                cacheName: nil)
        
        let monthlyRequest: NSFetchRequest<ScheduleEntity> = ScheduleEntity.fetchRequest()
        monthlyRequest.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        monthlyRequest.predicate = Self.monthlyPredicate()
        
        self.fetchResultMonthlyController = NSFetchedResultsController(fetchRequest: monthlyRequest,
                                                                managedObjectContext: context,
                                                                sectionNameKeyPath: nil,
                                                                cacheName: nil)
        
        super.init()
        
        fetchResultTodayController.delegate = self
        try? fetchResultTodayController.performFetch()
        
        fetchResultWeeklyController.delegate = self
        try? fetchResultWeeklyController.performFetch()
        
        fetchResultMonthlyController.delegate = self
        try? fetchResultMonthlyController.performFetch()
        
        print("today:", fetchResultTodayController.fetchedObjects?.count ?? 0)
        print("week:", fetchResultWeeklyController.fetchedObjects?.count ?? 0)
        print("month:", fetchResultMonthlyController.fetchedObjects?.count ?? 0)
        
        DispatchQueue.main.async { [weak self] in
            self?.todayItems = self?.fetchResultTodayController.fetchedObjects ?? []
            self?.weeklyItems = self?.fetchResultWeeklyController.fetchedObjects ?? []
            self?.monthlyItems = self?.fetchResultMonthlyController.fetchedObjects ?? []
        }
        
        // 자정 넘어가면 자동으로 오늘 predicate 갱신 + 리패치
        dayChangeObserver = NotificationCenter.default.addObserver(
            forName: .NSCalendarDayChanged,
            object: nil,
            queue: .main) { [weak self] _ in
                self?.refreshForNewDay()
            }
    }

    deinit {
        fetchResultTodayController.delegate = nil
        if let observer = dayChangeObserver { NotificationCenter.default.removeObserver(observer) }
    }
    
    private func refreshForNewDay() {
        let request = fetchResultTodayController.fetchRequest
        request.predicate = Self.todayPredicate()
        try? fetchResultTodayController.performFetch()
        todayItems = fetchResultTodayController.fetchedObjects ?? []
    }
    
    private func recomputeTodayStats() {
        todayScheduleCount = todayItems.count
        todayCompletedCount = todayItems
            .filter { ($0.isCompleted as? Bool) == true || ($0.isCompleted?.boolValue ?? false) }
            .count
        
        todayRemainCount = todayScheduleCount - todayCompletedCount
        todayCompletionRate = todayScheduleCount == 0 ? 0.0 : Double(todayCompletedCount) / Double(todayScheduleCount)
    }
    
    private func recomputeWeeklyStats() {
        weeklyScheduleCount = weeklyItems.count
        weeklyCompletedCount = weeklyItems
            .filter { ($0.isCompleted as? Bool) == true || ($0.isCompleted?.boolValue ?? false) }
            .count
        
        weeklyRemainCount = weeklyScheduleCount - weeklyCompletedCount
        weeklyCompletionRate = weeklyScheduleCount == 0 ? 0.0 : Double(weeklyCompletedCount) / Double(weeklyScheduleCount)
    }
    
    private func recomputeMonthlyStats() {
        monthlyScheduleCount = monthlyItems.count
        monthlyCompletedCount = monthlyItems
            .filter { ($0.isCompleted as? Bool) == true || ($0.isCompleted?.boolValue ?? false) }
            .count
        
        monthlyRemainCount = monthlyScheduleCount - monthlyCompletedCount
        monthlyCompletionRate = monthlyScheduleCount == 0 ? 0.0 : Double(monthlyCompletedCount) / Double(monthlyScheduleCount)
    }

    private static func todayPredicate() -> NSPredicate {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end   = cal.date(byAdding: .day, value: 1, to: start)!
        return NSPredicate(format: Self.predicateFormat, end as NSDate, start as NSDate)
    }
    
    private func todayRange() -> (Date, Date) {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        return (start, end)
    }
    
    private static func weeklyPredicate() -> NSPredicate {
        // 시작 요일 월요일
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = .current
        let week = cal.dateInterval(of: .weekOfYear, for: Date())!
        return NSPredicate(format: Self.predicateFormat, week.end as NSDate, week.start as NSDate)
    }
    
    private static func monthlyPredicate() -> NSPredicate {
        let cal = Calendar.current
        let month = cal.dateInterval(of: .month, for: Date())!
        return NSPredicate(format: Self.predicateFormat, month.end as NSDate, month.start as NSDate)
    }
}

extension ScheduleProgressViewModel {
    private var hasToday: Bool { todayScheduleCount > 0 }
    private var hasWeekly: Bool { weeklyScheduleCount > 0 }
    private var hasMonthly: Bool { monthlyScheduleCount > 0 }
    
    var progressIconName: String {
        hasToday ? "flag.pattern.checkered" : "calendar.badge.plus"
    }
    var progressWeeklyIconName: String {
        hasWeekly ? "flag.pattern.checkered" : "calendar.badge.plus"
    }
    var progressMonthlyIconName: String {
        hasMonthly ? "flag.pattern.checkered" : "calendar.badge.plus"
    }

    var progressInfo: (title: String, description: String) {
        if hasToday {
            return (
                title: "\(Int(todayCompletionRate * 100))%",
                description: "오늘 일정이\n\(todayRemainCount)개 남았어요."
            )
        } else {
            return (
                title: "일정이 없네요",
                description: "오늘 일정을\n추가해보세요."
            )
        }
    }
    
    var progressWeeklyInfo: (title: String, description: String) {
        if hasWeekly {
            return (
                title: "\(Int(weeklyCompletionRate * 100))%",
                description: "이번주 일정이\n\(weeklyRemainCount)개 남았어요."
            )
        } else {
            return (
                title: "일정이 없네요",
                description: "일정을\n추가해보세요."
            )
        }
    }
    
    var progressMonthlyInfo: (title: String, description: String) {
        if hasMonthly {
            return (
                title: "\(Int(monthlyCompletionRate * 100))%",
                description: "이번달 일정이\n\(monthlyRemainCount)개 남았어요."
            )
        } else {
            return (
                title: "일정이 없네요",
                description: "일정을\n추가해보세요."
            )
        }
    }

    var progressTitle: String {
        hasToday ? "오늘 달성률" : "오늘 일정"
    }
    
    var progressWeeklyTitle: String {
        hasWeekly ? "이번주 달성률" : "이번주 일정"
    }
    
    var progressMonthlyTitle: String {
        hasMonthly ? "이번달 달성률" : "이번달 일정"
    }

    var remainScheduleCountText: String {
        return "남은 일정 \(todayRemainCount)개"
    }
    
    var remainScheduleWeeklyCountText: String {
        return "남은 일정 \(weeklyRemainCount)개"
    }
    
    var remainScheduleMonthlyCountText: String {
        return "남은 일정 \(monthlyRemainCount)개"
    }

    var todayCompletionRateText: String {
        return "\(todayCompletionRate)%"
    }
}

extension ScheduleProgressViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        DispatchQueue.main.async { [weak self] in
            self?.todayItems = self?.fetchResultTodayController.fetchedObjects ?? []
            self?.weeklyItems = self?.fetchResultWeeklyController.fetchedObjects ?? []
            self?.monthlyItems = self?.fetchResultMonthlyController.fetchedObjects ?? []
        }
    }
}
