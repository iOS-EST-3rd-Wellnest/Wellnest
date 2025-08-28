//
//  ScheduleProgressViewModel.swift
//  Wellnest
//
//  Created by Jusung Kye on 8/27/25.
//

import Foundation
import CoreData

final class ScheduleProgressViewModel: NSObject, ObservableObject {
    var items: [ScheduleEntity] = [] {
        didSet { recomputeTodayStats() }
    }
    
    @Published private(set) var todayScheduleCount: Int = 0
    @Published private(set) var todayCompletedCount: Int = 0
    @Published private(set) var todayRemainCount: Int = 0
    @Published private(set) var todayCompletionRate: Double = 0.0

    private let context: NSManagedObjectContext
    private let fetchResultController: NSFetchedResultsController<ScheduleEntity>
    private var dayChangeObserver: NSObjectProtocol?

    init(context: NSManagedObjectContext) {
        self.context = context
        
        let request: NSFetchRequest<ScheduleEntity> = ScheduleEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        request.predicate = Self.todayPredicate()
        
        self.fetchResultController = NSFetchedResultsController(fetchRequest: request,
                                                                managedObjectContext: context,
                                                                sectionNameKeyPath: nil,
                                                                cacheName: nil)
        super.init()
        
        fetchResultController.delegate = self
        try? fetchResultController.performFetch()
        
        DispatchQueue.main.async { [weak self] in
            self?.items = self?.fetchResultController.fetchedObjects ?? []
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
        fetchResultController.delegate = nil
        if let observer = dayChangeObserver { NotificationCenter.default.removeObserver(observer) }
    }
    
    private func refreshForNewDay() {
        let request = fetchResultController.fetchRequest
        request.predicate = Self.todayPredicate()
        try? fetchResultController.performFetch()
        items = fetchResultController.fetchedObjects ?? []
    }
    
    private func recomputeTodayStats() {
        todayScheduleCount = items.count
        todayCompletedCount = items
            .filter { ($0.isCompleted as? Bool) == true || ($0.isCompleted?.boolValue ?? false) }
            .count
        
        todayRemainCount = todayScheduleCount - todayCompletedCount
        todayCompletionRate = todayScheduleCount == 0 ? 0.0 : Double(todayCompletedCount) / Double(todayScheduleCount)
    }
    
    private static func todayPredicate() -> NSPredicate {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end   = cal.date(byAdding: .day, value: 1, to: start)!
        return NSPredicate(format: "createdAt >= %@ AND createdAt < %@", start as NSDate, end as NSDate)
    }
    
    private func todayRange() -> (Date, Date) {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        return (start, end)
    }
}

extension ScheduleProgressViewModel {
    private var hasToday: Bool { todayScheduleCount > 0 }
    
    var progressIconName: String {
        hasToday ? "flag.pattern.checkered" : "calendar.badge.plus"
    }
    
    var progressInfo: (title: String, description: String) {
        if hasToday {
            return (
                title: "\(Int(todayCompletionRate * 100))%",
                description: "오늘 일정이\n\(todayRemainCount)개 남았어요"
            )
        } else {
            return (
                title: "일정이 없네요",
                description: "오늘 일정을\n추가해보세요"
            )
        }
    }
    
    var progressTitle: String {
        hasToday ? "오늘 달성률" : "오늘 일정"
    }
}

extension ScheduleProgressViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        DispatchQueue.main.async { [weak self] in
            self?.items = self?.fetchResultController.fetchedObjects ?? []
        }
    }
}
