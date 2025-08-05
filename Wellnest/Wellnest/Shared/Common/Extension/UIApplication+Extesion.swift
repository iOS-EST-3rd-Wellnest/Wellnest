//
//  UIApplication+Extesion.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/4/25.
//

import SwiftUI

extension UIApplication {
    static func hideKeyboard() {
        DispatchQueue.main.async {
            shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }
    }
}
