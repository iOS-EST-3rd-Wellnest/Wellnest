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

    var body: some View {
        GeometryReader { geo in
            let totalHeight = geo.size.width * 5 / 7

            VStack(spacing: Spacing.layout) {
                CalendarLayout {
                    ForEach(Date.weekdays.indices, id: \.self) { index in
                        Text(Date.weekdays[index])
                            .font(.subheadline)
                            .foregroundColor(Date.weekdayColor(at: index))
                    }
                }
                .frame(height: 16)

                CalendarLayout {
                    ForEach(planVM.calendarDates, id: \.self) { date in
                        dateCell(date: date)
                    }
                }
                .frame(height: totalHeight)
//                .background(Color.gray)
            }
            .padding(.horizontal)

        }
    }

    @ViewBuilder
    private func dateCell(date: Date) -> some View {
        let isCurrentMonth = calendar.isDate(date, equalTo: planVM.displayedMonth, toGranularity: .month)
        let isSameDay = calendar.isDate(date, inSameDayAs: planVM.selectedDate)
        let isSelected = isCurrentMonth && isSameDay
        let isToday = date.isToday

        VStack(spacing: 6) {
            Text("\(date.dayNumber)")
                .font(.system(size: 16))
                .foregroundStyle(isSelected ? .white : (isCurrentMonth ? date.weekdayColor : .secondary))
//                .background(Color.white)
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
//                    else {
//                        Circle()
//                        .stroke(Color.red)
//                            .frame(width: 32, height: 32)
//                    }
                }
                .onTapGesture {
                    planVM.select(date: date)
                }

            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .frame(width: 4, height: 4)
                        .foregroundColor(.green)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

#Preview {
    CalendarLayoutView(planVM: PlanViewModel())
}
