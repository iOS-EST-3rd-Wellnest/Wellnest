//
//  PlanViewModel.swift
//  Wellnest
//
//  Created by 박동언 on 8/4/25.
//

import Foundation
import SwiftUI

final class PlanViewModel: ObservableObject {
    @Published var selectedDate: Date
    @Published var displayedMonth: Date {
        didSet {
            updateDisplayedMonth()
            expandMonthsIfNeeded(from: displayedMonth)
        }
    }
    @Published var calendarDates: [Date]
    @Published var months: [Date]

	@Published var scheduleStore = ScheduleStore()

    private let calendar = Calendar.current

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

    var selectedDateScheduleItems: [ScheduleItem] {
        scheduleStore.scheduleItems(for: selectedDate)
    }

    func hasSchedule(for date: Date) -> Bool {
        scheduleStore.hasSchedule(for: date)
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
    }
}



