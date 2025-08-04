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

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: FocusableTextField
        weak var textField: UITextField?

        init(_ parent: FocusableTextField) {
            self.parent = parent
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.font = UIFont.systemFont(ofSize: 17)
        textField.delegate = context.coordinator
        context.coordinator.textField = textField
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text

        if isFirstResponder, !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        } else if !isFirstResponder, uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }
}
