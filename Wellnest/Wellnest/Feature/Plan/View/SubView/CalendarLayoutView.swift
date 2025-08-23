//
//  CalendarLayoutView.swift
//  Wellnest
//
//  Created by 박동언 on 8/5/25.
//

import SwiftUI

struct CalendarLayoutView: View {
    @ObservedObject var planVM: PlanViewModel
    let calendar = Calendar.current

    let month: Date
    var body: some View {
        CalendarLayout {
            ForEach(month.filledDatesOfMonth(), id: \.self) { date in
                dateCell(date: date)
            }
        }
    }

    @ViewBuilder
    private func dateCell(date: Date) -> some View {
        let isCurrentMonth = calendar.isDate(date, equalTo: month, toGranularity: .month)
        let isSameDay = calendar.isDate(date, inSameDayAs: planVM.selectedDate)
        let isSelected = isCurrentMonth && isSameDay
        let isToday = date.isToday

        let scheduleItems = planVM.scheduleStore.scheduleItems(for: date)
        let scheduleCount = scheduleItems.count

        VStack(spacing: 6) {
            Text("\(date.dayNumber)")
                .font(.system(size: 16))
                .foregroundStyle(isSelected ? .white : (isCurrentMonth ? date.weekdayColor : .secondary))
                .background {
                    if isSelected {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 28, height: 28)
                    } else if isToday {
                        Circle()
                            .stroke(Color.blue)
                            .frame(width: 28, height: 28)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.25)) {
                        if !calendar.isDate(date, equalTo: planVM.visibleMonth, toGranularity: .month) {
                            planVM.jumpToDate(date)
                        } else {
                            planVM.selectDate(date)
                        }
                    }

                }

            if scheduleCount > 0 && isCurrentMonth {
                HStack(spacing: 2) {
                    ForEach(0..<min(scheduleCount, 5), id: \.self) { index in
                        Circle()
                            .frame(width: 4, height: 4)
                            .foregroundStyle(Color.scheduleSolid(color: scheduleItems[index].backgroundColor))
                    }
                }
            } else {
                Circle()
                    .frame(width: 4, height: 4)
                    .foregroundStyle(.clear)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    CalendarLayoutView(planVM: PlanViewModel(), month: Date().startOfMonth)
}
