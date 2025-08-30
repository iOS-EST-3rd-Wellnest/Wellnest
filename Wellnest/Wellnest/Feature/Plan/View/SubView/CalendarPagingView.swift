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


    @Environment(\.horizontalSizeClass) private var hSize
    private var isRegularWidth: Bool { hSize == .regular }
    private var dayFontSize: CGFloat { isRegularWidth ? 22 : 16 }
    private var weekdayFont: Font { .system(size: dayFontSize, weight: .semibold) }
    private var weekdayBottomPadding: CGFloat { isRegularWidth ? Spacing.content + 4 : Spacing.content }

    @State private var screenWidth: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            CalendarLayout(mode: .intrinsic) {
                ForEach(Date.weekdays.indices, id: \.self) { idx in
                    Text(Date.weekdays[idx])
                        .font(weekdayFont)
                        .foregroundStyle(Date.weekdayColor(at: idx))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, weekdayBottomPadding)

            TabView(selection: $selection) {
                ForEach(pages.indices, id: \.self) { idx in
                    CalendarMonthView(planVM: planVM, month: pages[idx])
                        .padding(.horizontal)
                        .tag(idx)
                        .onDisappear {
                            handlePageDisappear(idx: idx)
                        }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: screenWidth > 0 ? calculateFixedMonthHeight(for: screenWidth) : nil)
            .clipped()
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

                planVM.recenterVisibleMonth(to: pages[new])

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

                Task { @MainActor in
                    isJumping = false
                }
            }
        }
        .background {
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        screenWidth = geo.size.width
                    }
                    .onChange(of: geo.size.width) { newWidth in
                        screenWidth = newWidth
                    }
            }
        }
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

    private func calculateFixedMonthHeight(for width: CGFloat) -> CGFloat {
        let horizontalPadding: CGFloat = 32
        let calendarWidth = width - horizontalPadding

        return CalendarLayout.fixedHeight(
            for: calendarWidth,
            columns: 7,
            spacing: 4,
            slots: 6,
            aspect: isRegularWidth ? 1.0 : 0.9
        )
    }
}

#Preview {
    CalendarPagingView(planVM: PlanViewModel())
}
