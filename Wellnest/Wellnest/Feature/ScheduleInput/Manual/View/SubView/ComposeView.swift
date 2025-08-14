//
//  ComposeView.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/13/25.
//

import SwiftUI

struct ComposeView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedBackgroundColor: Color

    @State private var selectedBackgroundColorIndex: Int?

    @State private var showColorPicker = false

    let colors: [Color] = [
        Color("accentButtonColor"),
        Color("accentCardBlueColor"),
        Color("accentCardGreenColor"),
        Color("accentCardPinkColor"),
        Color("accentCardYellowColor"),
        Color("backgroudColor"),
        Color("CustomSecondaryColor")
    ]

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {

                Text("배경색")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding()

                colorSelectionGrid(selectedIndex: $selectedBackgroundColorIndex, isBackground: true)
                Spacer()
            }
            .navigationTitle("색상 선택")
            .navigationBarTitleDisplayMode(.inline)
        }

    }

    @ViewBuilder
    private func colorSelectionGrid(selectedIndex: Binding<Int?>, isBackground: Bool) -> some View {
        let columns = Array(repeating: GridItem(.flexible()), count: 6)
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(0..<colors.count, id: \.self) { index in
                ZStack {
                    Circle()
                        .fill(colors[index])
                        .frame(width: 30, height: 30)
                }
                .onTapGesture {
                    selectedIndex.wrappedValue = index
                    selectedBackgroundColor = colors[index]
                    dismiss()
                }
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    ComposeView(selectedBackgroundColor: .constant(.accentCardBlue))
}
