//
//  CalendarHeaderView.swift
//  Wellnest
//
//  Created by 박동언 on 8/5/25.
//

import SwiftUI

struct CalendarHeaderView: View {
    @ObservedObject var planVM: PlanViewModel

    @State private var showPicker = false

    var body: some View {
        VStack {
            Button {
                withAnimation(.easeInOut) {
                    showPicker.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Text(planVM.displayedMonth.dateFormat("YYYY년 M월"))
                        .font(.title2)
                    Image(systemName: showPicker ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                        .font(.body)
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
        }
    }
}

#Preview {
    CalendarHeaderView(planVM: PlanViewModel())
}
