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

    var body: some View {
         GeometryReader { geo in
             VStack(spacing: 0) {
                 VStack {
                     Spacer()
                         .frame(height: geo.safeAreaInsets.top + Spacing.layout * 3)

                     DatePicker(
                         "",
                         selection: $planVM.selectedDate,
                         displayedComponents: [.date]
                     )
                     .datePickerStyle(.wheel)
                     .environment(\.locale, Locale(identifier: "ko_KR"))
                     .frame(maxWidth: .infinity)
                     .padding(.horizontal, 32)
                     .onChange(of: planVM.selectedDate) { newDate in
                         planVM.displayedMonth = newDate
                     }

                 }
//                 .frame(height: geo.size.height * 0.35)
                 .background(Color.white)
                 .clipShape(
                    RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                 )
                 .defaultShadow()
                 .offset(y: dragOffset)
                 .gesture(
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

                             withAnimation(.spring) {
                                 if value.translation.height < -100 {
                                     showDatePicker = false
                                 }
                                 dragOffset = 0
                             }
                         }
                 )
             }
         }
         .ignoresSafeArea(.all)
     }
}

#Preview {
    DatePickerSheetView(planVM: PlanViewModel(), showDatePicker: .constant(true))
}
