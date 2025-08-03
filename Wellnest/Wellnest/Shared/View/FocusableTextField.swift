//
//  FocusableTextField.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/2/25.
//

import SwiftUI
import UIKit

/// UIKit의 UITextField를 SwiftUI에서 포커스 제어 가능한 형태로 래핑한 커스텀 컴포넌트
struct FocusableTextField: UIViewRepresentable {

    /// 바인딩되는 텍스트 값
    @Binding var text: String

    /// 플레이스홀더 텍스트
    var placeholder: String

    /// 포커스를 가질지 여부
    var isFirstResponder: Bool

    // MARK: - Coordinator

    /// UITextFieldDelegate를 구현하는 Coordinator
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: FocusableTextField

        /// 실제 UITextField를 참조하기 위한 약한 참조
        weak var textField: UITextField?

        init(_ parent: FocusableTextField) {
            self.parent = parent
        }

        /// 텍스트가 변경될 때 SwiftUI 바인딩과 동기화
        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }
    }

    // Coordinator 생성
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // UITextField 생성 및 설정
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.font = UIFont.systemFont(ofSize: 17)
        textField.delegate = context.coordinator
        context.coordinator.textField = textField
        return textField
    }

    // SwiftUI 상태와 UIKit 뷰 동기화
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text

        // 포커스 상태에 따라 키보드 표시/해제
        if isFirstResponder, !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        } else if !isFirstResponder, uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }
}

/// 뷰 전체에 탭 제스처를 추가하여 키보드를 내리는 뷰모디파이어
struct TapToDismissKeyboard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                TapToDismissView().allowsHitTesting(true)
            )
    }
}

/// 배경 뷰에 UITapGestureRecognizer를 추가하여 키보드를 닫는 역할을 수행
private struct TapToDismissView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.dismissKeyboard)
        )
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        @objc func dismissKeyboard() {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        }
    }
}

