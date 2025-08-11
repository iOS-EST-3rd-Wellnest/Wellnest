//
//  ScheduleInputTextField.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/11/25.
//

import SwiftUI

struct ScheduleInputTextField: View {
    // 일정 제목
    @State private var title: String = ""

    @State private var selectedColor: Color = .blue

    // 초기에 첫번째 텍스트 필드에 focus.
    @State private var isTextFieldFocused: Bool = true

    @State private var currentFocus: InputField? = .title

    @State private var location: String = ""

    @State private var showLocationSearchSheet = false


    enum InputField: Hashable {
        case title
        case detail
    }
    
    var body: some View {
        VStack {
            HStack {
                FocusableTextField(
                    text: $title,
                    placeholder: "일정을 입력하세요.",
                    isFirstResponder: currentFocus == .title,
                    returnKeyType: .next,
                    keyboardType: .default,
                    onReturn: {
                        currentFocus = .detail
                    },
                    onEditing: {
                        if currentFocus != .title {
                            currentFocus = .title
                        }
                    }
                )
                ColorPicker("배경 색상 선택", selection: $selectedColor)
                    .labelsHidden()
            }
            Divider()

            HStack {
                FocusableTextField(
                    text: $location,
                    placeholder: "장소",
                    isFirstResponder: currentFocus == .detail,
                    returnKeyType: .done,
                    keyboardType: .default,
                    onReturn: {
                        currentFocus = nil
                    },
                    onEditing: {
                        if currentFocus != .detail {
                            currentFocus = .detail
                        }
                    }
                )

                Button {
                    showLocationSearchSheet = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.black)
                }
            }
            .sheet(isPresented: $showLocationSearchSheet) {
                LocationSearchView(selectedLocation: $location, isPresented: $showLocationSearchSheet)
            }
            Divider()
        }

    }
}

#Preview {
    ScheduleInputTextField()
}
