//
//  View+Modifier.swift
//  Wellnest
//
//  Created by 박동언 on 8/1/25.
//

import SwiftUI

extension View {
    func defaultShadow() -> some View {
        self.shadow(radius: 6, x: 2, y: 2)
    }

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
