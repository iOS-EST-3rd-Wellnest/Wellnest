//
//  FocusableTextField.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/2/25.
//

import SwiftUI
import UIKit

struct FocusableTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var isFirstResponder: Bool
    
    // 키보드 설정 옵션
    var returnKeyType: UIReturnKeyType = .default
    var keyboardType: UIKeyboardType = .default
    var isSecureTextEntry: Bool = false
    var clearButtonMode: UITextField.ViewMode = .never

    var onReturn: (() -> Void)? = nil
    var onEditing: (() -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.placeholder = placeholder
        textField.returnKeyType = returnKeyType
        textField.keyboardType = keyboardType
        textField.autocorrectionType = .no // 자동완성 비활성화
        textField.spellCheckingType = .no // 철자검사 비활성화
        textField.clearButtonMode = clearButtonMode
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
        
        DispatchQueue.main.async {
            if isFirstResponder && !uiView.isFirstResponder {
                uiView.becomeFirstResponder()
            } else if !isFirstResponder && uiView.isFirstResponder {
                uiView.resignFirstResponder()
            }
        }

        // 업데이트 시에도 키보드 설정 동기화
        uiView.returnKeyType = returnKeyType
        uiView.keyboardType = keyboardType

        uiView.isSecureTextEntry = isSecureTextEntry
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        let parent: FocusableTextField

        init(_ parent: FocusableTextField) {
            self.parent = parent
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.onEditing?()
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.onReturn?()
            return true
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }
    }
}

