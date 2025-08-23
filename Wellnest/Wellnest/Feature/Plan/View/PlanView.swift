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
        GeometryReader { geo in
            ZStack {
                VStack(spacing: 0) {
                    if isSheetExpanded {
                        CalendarWeekView(planVM: planVM)
                    } else {
                        CalendarPagingView(planVM: planVM, screenWidth: geo.size.width)
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
                            withAnimation(.spring) {
                                showDatePicker = false
                            }
                        }
                        .zIndex(1)
                }

                if showDatePicker {
                    DatePickerSheetView(
                        planVM: planVM,
                        showDatePicker: $showDatePicker,
                        headerHeight: headerHeight
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(2)
                }

                VStack(spacing: 0) {
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
                }
                .padding(.horizontal)
                .zIndex(3)
            }
            .ignoresSafeArea(edges: .bottom)
            .onAppear {
                planVM.scheduleStore.loadScheduleData()
            }
        }
    }
}

#Preview {
    PlanView()
}
