//
//  ComposeView.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/13/25.
//

import SwiftUI
import UIKit

struct ComposeData {
    var title: String = ""
    var backgroundColor: Color = .white
    var textColor: Color = .black
}
extension Notification.Name {
    static let eventDidInsert = Notification.Name("eventDidInsert")
}


struct ComposeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var data = ComposeData()

    @State private var selectedBackgroundColorIndex: Int?
    @State private var selectedTextColorIndex: Int?

    @State private var showColorPicker = false
    @State private var isBackgroundColorPicker = true
    @State private var customColor = Color.white

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

//                Text("글자색")
//                    .font(.headline)
//                    .foregroundColor(.secondary)
//                    .padding()
//                colorSelectionGrid(selectedIndex: $selectedTextColorIndex, isBackground: false)

                Button("저장") {
                    NotificationCenter.default.post(name: .eventDidInsert, object: nil)
                    dismiss()
                }
                .padding()
            }
            .sheet(isPresented: $showColorPicker) {
                UIColorPickerWrapper(
                    selectedColor: $customColor,                    // ← Color 바인딩
                    onSelect: { color in
                        if isBackgroundColorPicker {
                            data.backgroundColor = color
                        } else {
                            data.textColor = color
                        }
                    }
                )
            }
            .onAppear {
                selectedBackgroundColorIndex = Int.random(in: 0..<colors.count)
                data.backgroundColor = colors[selectedBackgroundColorIndex!]

                selectedTextColorIndex = Int.random(in: 0..<colors.count)
                data.textColor = colors[selectedTextColorIndex!]
            }
            .navigationTitle("색상")
            .navigationBarTitleDisplayMode(.inline)
        }

    }

    @ViewBuilder
    private func colorSelectionGrid(selectedIndex: Binding<Int?>, isBackground: Bool) -> some View {
        let columns = Array(repeating: GridItem(.flexible()), count: 6)
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(0..<colors.count + 1, id: \.self) { index in
                if index == colors.count {
                    Button {
                        isBackgroundColorPicker = isBackground
                        showColorPicker = true
                    } label: {
                        Image("color-picker")
//                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 32, height: 32)
                    }
                } else {
                    let uiColor = colors[index]
                    let isSelected = selectedIndex.wrappedValue == index

                    ColorCircleView(color: colors[index], isSelected: isSelected)
                        .onTapGesture {
                            selectedIndex.wrappedValue = index
                            if isBackground {
                                data.backgroundColor = colors[index]
                            } else {
                                data.textColor = colors[index]
                            }
                        }
                }
            }
        }
        .padding(.horizontal)
    }
}

struct ColorCircleView: View {
    let color: Color
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 30, height: 30)
                .overlay(
                    Circle()
                        .stroke(.black, lineWidth: isSelected ? 3 : 1)
                )
            if isSelected {
                // 배경 명도에 따라 체크 색 가변 (선택)
                let ui = UIColor(color)
                let check: Color = ui.isLight ? .black : .white
                Image(systemName: "checkmark")
                    .font(.headline)
                    .foregroundStyle(check)
            }
        }
    }
}

extension UIColor {
    var isLight: Bool {
        // 다크/라이트 등 동적 색 먼저 해석
        let resolved = self.resolvedColor(with: UIScreen.main.traitCollection)

        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if resolved.getRed(&r, green: &g, blue: &b, alpha: &a) {          // ✅ 인스턴스 메서드로 호출
            let yiq = (299*r + 587*g + 114*b) / 1000  // 0...1
            return yiq >= 0.5
        }

        // RGB가 아니면 그레이스케일로 재시도
        var white: CGFloat = 0
        if resolved.getWhite(&white, alpha: &a) {
            return white >= 0.5
        }

        // 그 외 색공간은 기본값
        return true
    }
}

// SwiftUI.Color도 쓰고 있다면 브리지 하나 추가
extension Color {
    var isLight: Bool { UIColor(self).isLight }
}

struct UIColorPickerWrapper: UIViewControllerRepresentable {
    @Binding var selectedColor: Color
    var onSelect: (Color) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIColorPickerViewController {
        let picker = UIColorPickerViewController()
        picker.delegate = context.coordinator
        picker.selectedColor = UIColor(selectedColor)   // Color → UIColor
        picker.supportsAlpha = false
        picker.view.backgroundColor = .systemGray6
        return picker
    }

    func updateUIViewController(_ uiViewController: UIColorPickerViewController, context: Context) {
        uiViewController.selectedColor = UIColor(selectedColor) // 동기화
    }

    class Coordinator: NSObject, UIColorPickerViewControllerDelegate {
        var parent: UIColorPickerWrapper
        init(_ parent: UIColorPickerWrapper) { self.parent = parent }

        func colorPickerViewControllerDidFinish(_ vc: UIColorPickerViewController) {
            parent.onSelect(Color(uiColor: vc.selectedColor))   // UIColor → Color
        }

        func colorPickerViewController(_ vc: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
            if !continuously {
                parent.selectedColor = Color(uiColor: color)     // 실시간 바인딩
            }
        }
    }
}

//#Preview {
//    ComposeView()
//}
