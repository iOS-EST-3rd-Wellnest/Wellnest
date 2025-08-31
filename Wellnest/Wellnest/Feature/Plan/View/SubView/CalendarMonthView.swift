//
//  CalendarMonthView.swift
//  Wellnest
//
//  Created by 박동언 on 8/5/25.
//

import SwiftUI

struct CalendarMonthView: View {
    @ObservedObject var planVM: PlanViewModel
    let calendar = Calendar.current

    @Environment(\.horizontalSizeClass) private var hSize
    private var isRegularWidth: Bool { hSize == .regular }

    private var dayFontSize: CGFloat { isRegularWidth ? 22 : 16 }
    private var selectedCircleSize: CGFloat { isRegularWidth ? 34 : 28 }
    private var dotSize: CGFloat { isRegularWidth ? 5 : 4 }
    private var cellTopPadding: CGFloat { isRegularWidth ? Spacing.content + 2 : Spacing.content }

    let month: Date
    var body: some View {
        CalendarLayout(mode: .fixedSlots(slots: 6, aspectRatio: 0.9)) {
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

        let scheduleItems = planVM.items(for: date)
        let scheduleCount = scheduleItems.count

        VStack(spacing: 8) {
            Text("\(date.dayNumber)")
                .font(.system(size: dayFontSize))
                .foregroundStyle(isSelected ? .white : (isCurrentMonth ? date.weekdayColor : .secondary))
                .background {
                    if isSelected {
                        Circle()
                            .fill(.wellnestOrange)
                            .frame(width: selectedCircleSize, height: selectedCircleSize)
                    } else if isToday {
                        Circle()
                            .stroke(.wellnestOrange, lineWidth: 1)
                            .frame(width: selectedCircleSize, height: selectedCircleSize)
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
                            .frame(width: dotSize, height: dotSize)
                            .foregroundStyle(Color.scheduleDot(color: scheduleItems[index].backgroundColor))
                    }
                }
            } else {
                Circle()
                    .frame(width: dotSize, height: dotSize)
                    .foregroundStyle(.clear)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, cellTopPadding)
    }
}

#Preview {
    CalendarMonthView(planVM: PlanViewModel(), month: Date().startOfMonth)
}
