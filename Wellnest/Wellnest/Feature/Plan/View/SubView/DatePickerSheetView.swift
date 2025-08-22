//
//  DatePickerSheet.swift
//  Wellnest
//
//  Created by 박동언 on 8/8/25.
//

import SwiftUI

struct DatePickerSheetView: View {
    @ObservedObject var planVM: PlanViewModel

    @Binding var showDatePicker: Bool

    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false

    let headerHeight: CGFloat

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                VStack {
                    Color.clear
                        .frame(height: geo.safeAreaInsets.top + headerHeight + Spacing.layout * 2 + Spacing.content)


                    DatePicker(
                        "",
                        selection: $planVM.selectedDate,
                        displayedComponents: [.date]
                    )
                    .labelsHidden()
                    .datePickerStyle(.wheel)
                    .environment(\.locale, Locale(identifier: "ko_KR"))
                    .frame(maxWidth: .infinity)
                    .onChange(of: planVM.selectedDate) { newDate in
                        planVM.jumpToDate(newDate)
                    }
                }
                .background(Color.white)
                .clipShape(
                    RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                )
                .defaultShadow()
                .offset(y: dragOffset)
                .gesture(dragGesture)
            }
        }
        .ignoresSafeArea(.all)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                }

                if value.translation.height < 0 {
                    dragOffset = value.translation.height
                }
            }
            .onEnded { value in
                isDragging = false

                if value.translation.height < -100 {
                    showDatePicker = false
                }

                dragOffset = 0
            }
    }
}

#Preview {
    DatePickerSheetView(planVM: PlanViewModel(), showDatePicker: .constant(true), headerHeight: 80)
}
