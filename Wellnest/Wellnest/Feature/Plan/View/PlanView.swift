//
//  PlanView.swift
//  Wellnest
//
//  Created by 박동언 on 8/1/25.
//

import SwiftUI

struct PlanView: View {
    @ObservedObject var planVM: PlanViewModel

    @State private var isSheetExpanded: Bool = false
    @State private var headerHeight: CGFloat = 0

    @Binding  var showDatePicker: Bool
    @Binding var selectedTab: TabBarItem
    @Binding var selectedCreationType: ScheduleCreationType?

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height

            if isLandscape {
                ZStack {
                    HStack(spacing: 0) {
                        VStack(spacing: 0) {
                            CalendarHeaderView(planVM: planVM, showDatePicker: $showDatePicker)
                                .padding(.vertical, Spacing.content)
                                .padding(.bottom, Spacing.content)
                                .padding(.horizontal)

                            CalendarPagingView(planVM: planVM)
                        }

                        Divider()

                        ScheduleSheetView(planVM: planVM, isSheetExpanded: $isSheetExpanded, selectedTab: $selectedTab, selectedCreationType: $selectedCreationType, asSidePanel: true)
                            .frame(maxHeight: .infinity)
                    }

                    if showDatePicker {
                        Rectangle()
                            .fill(.ultraThinMaterial)
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
                            headerHeight: 0
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(2)
                    }
                }
                .ignoresSafeArea(edges: .bottom)
            } else {
                ZStack {
                    
                    VStack(spacing: 0) {
                        if isSheetExpanded {
                            CalendarWeekView(planVM: planVM)
                        } else {
                            CalendarPagingView(planVM: planVM)
                        }

                        ScheduleSheetView(planVM: planVM, isSheetExpanded: $isSheetExpanded, selectedTab: $selectedTab, selectedCreationType: $selectedCreationType)
                            .frame(maxHeight: .infinity)
                            .padding(.top)
                    }
                    .padding(.top, headerHeight + Spacing.content)
                    .zIndex(0)

                    if showDatePicker {
                        Rectangle()
                            .fill(.ultraThinMaterial)
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
                            .padding(.bottom, Spacing.content)
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

            }
        }
    }
}

#Preview {
    PlanView(planVM: PlanViewModel(), showDatePicker: .constant(false), selectedTab: .constant(.plan), selectedCreationType: .constant(.createByUser))
}
