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
    @State private var headerHeight: CGFloat = 0

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if isSheetExpanded {
                    CalendarWeekView(planVM: planVM)
                } else {
                    CalendarPagingView(planVM: planVM)
                }

                ScheduleSheetView(planVM: planVM, isSheetExpanded: $isSheetExpanded)
                    .frame(maxHeight: .infinity)
                    .padding(.top)
            }
            .padding(.top, headerHeight)
            .zIndex(0)
            
            if showDatePicker {
                Color.black.opacity(0.3)
                    .ignoresSafeArea(.all)
                    .onTapGesture {
                            showDatePicker = false
                    }
                    .zIndex(1)
            }

            if showDatePicker {
                DatePickerSheetView(
                    planVM: planVM,
                    showDatePicker: $showDatePicker,
                    headerHeight: headerHeight
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .top),
                    removal: .move(edge: .top)
                ))
                .zIndex(2)
            }

            VStack(spacing: 0) {
                HStack {
                    CalendarHeaderView(planVM: planVM, showDatePicker: $showDatePicker)
                        .padding(.vertical, Spacing.content)
                        .background {
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear {
                                        headerHeight = geo.size.height
                                    }
                                    .onChange(of: geo.size.height) { newValue in
                                        headerHeight = newValue
                                    }
                            }
                        }

                    Spacer()

                    Button {
                        planVM.selectedDate = Date().startOfDay
                        planVM.displayedMonth = Date().startOfMonth
                    } label: {
                        Text("오늘")
                    }
                }


                Spacer()
            }
            .padding(.horizontal)
            .zIndex(3)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview {
    PlanView()
}
