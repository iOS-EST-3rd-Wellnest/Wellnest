//
//  ComposeView.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/13/25.
//

import SwiftUI

struct ColorPickerView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedColorName: String
    @State private var selectedBackgroundColorIndex: Int?
    @State private var showColorPicker = false

    private let colorNames: [String] = [
        "sweetiePink",
        "creamyOrange",
        "pleasantLight",
        "tenderBreeze",
        "fluffyBlue",
        "milkyBlue",
        "babyLilac",
        "oatmeal"
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
            ForEach(colorNames, id: \.self) { colorName in
                ZStack {
                    Circle()
                        .fill(Color(colorName))
                        .frame(width: 30, height: 30)
                }
                .onTapGesture {
                    selectedColorName = colorName
                    dismiss()
                }
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    ColorPickerView(selectedColorName: .constant("accentCardBlue"))
}
