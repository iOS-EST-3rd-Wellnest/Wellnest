//
//  PlanViewModel.swift
//  Wellnest
//
//  Created by 박동언 on 8/4/25.
//

import Foundation

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

    private let calendar = Calendar.current

    init(selectedDate: Date = Date()) {
        let calendar = Calendar.current
        let normalized = selectedDate.startOfDay

        self.selectedDate = normalized
        self.displayedMonth = normalized.startOfMonth ?? normalized
        self.calendarDates = normalized.filledDatesOfMonth()
        self.months = (-12...12).compactMap {
            calendar.date(byAdding: .month, value: $0, to: normalized.startOfMonth ?? normalized)
        }
    }
}

extension PlanViewModel {
    private func updateDisplayedMonth() {
        calendarDates = displayedMonth.filledDatesOfMonth()

//        if !calendar.isDate(selectedDate, equalTo: displayedMonth, toGranularity: .month) {
//             selectedDate = displayedMonth
//         }
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
            displayedMonth = normalized.startOfMonth ?? normalized
            calendarDates = displayedMonth.filledDatesOfMonth()
        }
    }
}



