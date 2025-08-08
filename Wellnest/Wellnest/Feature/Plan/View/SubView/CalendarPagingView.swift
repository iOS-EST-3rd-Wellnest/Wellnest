//
//  CalendarPagingView.swift
//  Wellnest
//
//  Created by 박동언 on 8/6/25.
//

import SwiftUI

struct CalendarPagingView: View {
    @ObservedObject var planVM: PlanViewModel

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                CalendarLayout(fixedCellHeight: planVM.calenderHeight(width: geo.size.width, rows: 1)) {
                    ForEach(Date.weekdays.indices, id: \.self) { index in
                        Text(Date.weekdays[index])
                            .font(.subheadline)
                            .foregroundStyle(Date.weekdayColor(at: index))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                }
                .padding(.horizontal)

                TabView(selection: $planVM.displayedMonth) {
                    ForEach(planVM.months, id: \.self) { month in
                        CalendarLayoutView(planVM: planVM)
                            .padding(.horizontal)
                            .tag(month)
                    }
                }
                .frame(height: planVM.calenderHeight(width: geo.size.width, rows: 5))
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .frame(height: planVM.calenderHeight(rows: 1) + planVM.calenderHeight(rows: 5))
    }
}

#Preview {
    CalendarPagingView(planVM: PlanViewModel())
}
