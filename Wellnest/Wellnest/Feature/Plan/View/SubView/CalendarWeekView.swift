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

    @State private var weekHeight: CGFloat = 0

    var body: some View {
            ZStack {
                HStack(spacing: 4) {
                    ForEach(planVM.selectedDate.filledWeekDates(), id: \.self) { date in
                        VStack(spacing: 0) {
                            columnBackground(date: date)
                        }
                    }
                }
                .padding(.horizontal)

                VStack(spacing: Spacing.layout) {
                    CalendarLayout(mode: .intrinsic) {
                        ForEach(planVM.selectedDate.filledWeekDates(), id: \.self) { date in
                            let isSelected = calendar.isDate(date, inSameDayAs: planVM.selectedDate)

                            Text(Date.weekdays[date.weekdayIndex])
                                .font(.subheadline)
                                .foregroundStyle(isSelected ? Color.white : date.weekdayColor)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .allowsHitTesting(false)
                        }
                    }

                    CalendarLayout(mode: .intrinsic) {
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
                .background {
                    GeometryReader { geo in
                        Color.clear
                            .onAppear {
                                if weekHeight == 0 {
                                    weekHeight = geo.size.height
                                }
                            }
                    }
                }
            }
            .frame(height: weekHeight)
    }

    @ViewBuilder
    private func columnBackground(date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: planVM.selectedDate)
        let isToday = date.isToday

        RoundedRectangle(cornerRadius: CornerRadius.medium)
            .foregroundStyle(Color.clear)
            .frame(maxWidth: .infinity)
            .frame(height: weekHeight)
            .padding(.vertical, Spacing.content)
            .overlay {
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: CornerRadius.medium)
                            .foregroundStyle(.wellnestOrange)
                    } else if isToday {
                        RoundedRectangle(cornerRadius: CornerRadius.medium)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                planVM.selectDate(date)
            }
    }
}

#Preview {
    CalendarWeekView(planVM: PlanViewModel())
}
