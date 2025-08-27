//
//  CalendarWeekView.swift
//  Wellnest
//
//  Created by 박동언 on 8/6/25.
//

import SwiftUI

struct CalendarWeekView: View {
    @ObservedObject var planVM: PlanViewModel


    let calendar = Calendar.current

    var body: some View {
        GeometryReader { geo in

            ZStack {
                HStack(spacing: 4) {
                    ForEach(planVM.selectedDate.filledWeekDates(), id: \.self) { date in
                        columnBackground(date: date, width: geo.size.width)
                    }
                }
                .padding(.horizontal)

                VStack(spacing: 0) {
                    CalendarLayout(fixedHeight: planVM.calendarHeight(width: geo.size.width, rows: 1)) {
                        ForEach(planVM.selectedDate.filledWeekDates(), id: \.self) { date in
                            let isSelected = calendar.isDate(date, inSameDayAs: planVM.selectedDate)

                            Text(Date.weekdays[date.weekdayIndex])
                                .font(.subheadline)
                                .foregroundStyle(isSelected ? Color.white : date.weekdayColor)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .allowsHitTesting(false)
                        }
                    }

                    CalendarLayout(fixedHeight: planVM.calendarHeight(width: geo.size.width, rows: 1)) {
                        ForEach(planVM.selectedDate.filledWeekDates(), id: \.self) { date in

                            let isSelected = calendar.isDate(date, inSameDayAs: planVM.selectedDate)

                            Text("\(date.dayNumber)")
                                .font(.system(size: 16))
                                .foregroundStyle(isSelected ? Color.white : date.weekdayColor)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .allowsHitTesting(false)
                        }
                    }
                }
                .padding(.horizontal)
                .allowsHitTesting(false)
            }
        }
        .frame(height: planVM.calendarHeight(rows: 1) * 2)
    }

    @ViewBuilder
    private func columnBackground(date: Date, width: CGFloat) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: planVM.selectedDate)
        let isToday = date.isToday

        RoundedRectangle(cornerRadius: CornerRadius.medium)
            .foregroundStyle(Color.clear)
            .overlay(
                 Group {
                     if isSelected {
                         RoundedRectangle(cornerRadius: CornerRadius.medium)
                             .foregroundStyle(.wellnestOrange)
                     } else if isToday {
                         RoundedRectangle(cornerRadius: CornerRadius.medium)
                             .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                     }
                 }
             )
            .frame(maxWidth: .infinity)
            .frame(height: planVM.calendarHeight(width: width, rows: 1) * 2)
            .contentShape(Rectangle())
            .onTapGesture {
                planVM.selectDate(date)
            }
    }
}

#Preview {
    CalendarWeekView(planVM: PlanViewModel())
}
