//
//  CalendarPagingView.swift
//  Wellnest
//
//  Created by 박동언 on 8/6/25.
//

import SwiftUI

struct CalendarPagingView: View {
    @ObservedObject var planVM: PlanViewModel

    @State private var selection: Int = 3
    @State private var pages: [Date] = []

    @State private var isDragging = false
    @State private var pendingRecenterMonth: Date?
    @State private var isJumping = false
    @State private var previousSelection: Int = 3

    let screenWidth: CGFloat

    var body: some View {
        let rowH1 = planVM.calendarHeight(width: screenWidth, rows: 1)
        let rowH5 = planVM.calendarHeight(width: screenWidth, rows: 5)
        let totalH = rowH1 + rowH5

        VStack(spacing: 0) {
            CalendarLayout(fixedHeight: rowH1) {
                ForEach(Date.weekdays.indices, id: \.self) { idx in
                    Text(Date.weekdays[idx])
                        .font(.subheadline)
                        .foregroundStyle(Date.weekdayColor(at: idx))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(.horizontal)

            TabView(selection: $selection) {
                ForEach(pages.indices, id: \.self) { idx in
                    CalendarLayoutView(planVM: planVM, month: pages[idx])
                        .padding(.horizontal)
                        .tag(idx)
                        .onDisappear {
                            handlePageDisappear(idx: idx)
                        }
                }
            }
            .frame(height: rowH5)
            .tabViewStyle(.page(indexDisplayMode: .never))
            .simultaneousGesture(
                DragGesture()
                    .onChanged { _ in
                        if !isDragging { isDragging = true }
                    }
                    .onEnded { _ in
                        isDragging = false

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if !isJumping && selection != previousSelection {
                                planVM.selectDate(pages[selection])
                                previousSelection = selection
                            }
                        }

                        if let center = pendingRecenterMonth {
                            commitRecenter(centerMonth: center)
                            pendingRecenterMonth = nil
                        }
                    }
            )
            .onAppear {
                let center = planVM.visibleMonth
                pages = planVM.generatePageMonths(center: center)
                selection = 3
            }
            .onChange(of: selection) { new in
                guard pages.indices.contains(new) else { return }

                if isJumping { return }

                planVM.updateVisibleMonthOnly(pages[new])

                if new == 5 {
                    planVM.stagePrefetch(direction: +1)
                }
                if new == 1 {
                    planVM.stagePrefetch(direction: -1)
                }

                if !isDragging {
                    planVM.selectDate(pages[new])
                    previousSelection = new
                }
            }
            .onChange(of: planVM.jumpToken) { _ in
                isJumping = true

                let centerMonth = planVM.visibleMonth
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    selection = 3
                }

                pages = planVM.generatePageMonths(center: centerMonth)
                previousSelection = 3

                DispatchQueue.main.async {
                    isJumping = false
                }
            }
        }
        .frame(height: totalH)
    }

    private func handlePageDisappear(idx: Int) {
        if selection == 6, idx == 5 {
            enqueueRecenter()
        } else if selection == 0, idx == 1 {
            enqueueRecenter()
        }
    }

    private func enqueueRecenter() {
        let centerMonth = pages[selection]
        if isDragging {
            pendingRecenterMonth = centerMonth
        } else {
            commitRecenter(centerMonth: centerMonth)
        }
    }

    private func commitRecenter(centerMonth: Date) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            selection = 3
        }

        planVM.recenterVisibleMonth(to: centerMonth)
        pages = planVM.generatePageMonths(center: centerMonth)
    }
}

#Preview {
    CalendarPagingView(planVM: PlanViewModel(), screenWidth: 390)
}
