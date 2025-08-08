//
//  PlanView.swift
//  Wellnest
//
//  Created by 박동언 on 8/1/25.
//

import SwiftUI

struct PlanView: View {
    @StateObject private var planVM = PlanViewModel()

    @State private var isSheetExpanded: Bool = false
    @State private var showDatePicker: Bool = false

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    CalendarHeaderView(planVM: planVM,  showDatePicker: $showDatePicker)
                        .padding()

                    if isSheetExpanded {
                        CalendarWeekView(planVM: planVM)
                    } else {
                        CalendarPagingView(planVM: planVM)
                    }
                }

                ScheduleSheetView(planVM: planVM, isSheetExpanded: $isSheetExpanded)
                    .frame(maxHeight: .infinity)
                    .padding(.top)
            }
            .overlay {
                if showDatePicker {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea(.all)
                        .onTapGesture {
                            withAnimation(.spring) {
                                showDatePicker = false
                            }
                        }

                }
            }
            .overlay {
                if showDatePicker {
                    DatePickerSheetView(
                        planVM: planVM,
                        showDatePicker: $showDatePicker
                    )
                    .transition(.asymmetric(
                         insertion: .move(edge: .top),
                         removal: .move(edge: .top)
                     ))
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview {
    PlanView()
}
