//
//  CalendarHeaderView.swift
//  Wellnest
//
//  Created by 박동언 on 8/5/25.
//

import SwiftUI

struct CalendarHeaderView: View {
    @ObservedObject var planVM: PlanViewModel

    @Binding var showDatePicker: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    withAnimation(.spring) {
                        showDatePicker.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(planVM.displayedMonth.dateFormat("YYYY년 M월"))
                            .font(.title2)
                            .fontWeight(.semibold)
                        Image(systemName:"arrowtriangle.down.fill")
                            .font(.body)
                            .rotationEffect(.degrees(showDatePicker ? 180 : 0))
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.25)) {
                        planVM.selectedDate = Date().startOfDay
                        planVM.displayedMonth = Date().startOfMonth
                    }
                } label: {
                    Text("오늘")
                        .font(.body)
                }
            }
        }
    }
}

#Preview {
    CalendarHeaderView(planVM: PlanViewModel(), showDatePicker: .constant(true))
}
