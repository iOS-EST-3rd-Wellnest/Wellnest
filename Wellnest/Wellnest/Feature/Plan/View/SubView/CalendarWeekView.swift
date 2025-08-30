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

    @Environment(\.horizontalSizeClass) private var hSize
    private var isRegularWidth: Bool { hSize == .regular }

    private var dayFontSize: CGFloat { isRegularWidth ? 22 : 16 }
    private var weekdayFont: Font { .system(size: dayFontSize, weight: .semibold) }
    private var dotSize: CGFloat { isRegularWidth ? 5 : 4 }


    @State private var weekHeight: CGFloat = 0

    var body: some View {
        let dates = planVM.selectedDate.filledWeekDates()

        VStack(spacing: Spacing.layout) {
            ZStack {
                CalendarLayout(mode: .intrinsic) {
                    ForEach(dates, id: \.self) { date in
                        columnBackground(date: date)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .contentShape(Rectangle())
                            .onTapGesture { planVM.selectDate(date) }
                    }
                }

                CalendarLayout(mode: .intrinsic) {
                    ForEach(dates, id: \.self) { date in
                        let isSelected = calendar.isDate(date, inSameDayAs: planVM.selectedDate)

                        VStack(spacing: Spacing.layout) {
                            Text(Date.weekdays[date.weekdayIndex])
                                .font(weekdayFont)
                                .foregroundStyle(isSelected ? .white : date.weekdayColor)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .allowsHitTesting(false)

                            Text("\(date.dayNumber)")
                                .font(.system(size: dayFontSize))
                                .foregroundStyle(isSelected ? .white : date.weekdayColor)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .allowsHitTesting(false)
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.layout)
            .background {
                GeometryReader { geo in
                    Color.clear.onAppear {
                        if weekHeight == 0 {
                            weekHeight = geo.size.height
                        }
                    }
                }
            }
            .frame(height: weekHeight == 0 ? nil : weekHeight)

            CalendarLayout(mode: .intrinsic) {
                ForEach(dates, id: \.self) { date in
                    let scheduleItems = planVM.items(for: date)
                    let scheduleCount = scheduleItems.count

                    Group {
                        if scheduleCount > 0  {
                            HStack(spacing: 2) {
                                ForEach(0..<min(scheduleCount, 5), id: \.self) { index in
                                    Circle()
                                        .frame(width: dotSize, height: dotSize)
                                        .foregroundStyle(
                                            Color.scheduleDot(color: scheduleItems[index].backgroundColor)
                                        )
                                }
                            }
                        } else {
                            Circle()
                                .frame(width: dotSize, height: dotSize)
                                .foregroundStyle(.clear)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.horizontal, Spacing.layout)
        }
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
