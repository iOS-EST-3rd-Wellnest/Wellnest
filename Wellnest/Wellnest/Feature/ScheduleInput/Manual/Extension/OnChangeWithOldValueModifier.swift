//
//  View+Modifier.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/5/25.
//

import SwiftUI

extension View {
    func onChangeWithOldValue<Value: Equatable>(
        of value: Value,
        perform: @escaping (_ oldValue: Value, _ newValue: Value) -> Void
    ) -> some View {
        modifier(OnChangeWithOldValueModifier(value: value, perform: perform))
    }
}

private struct OnChangeWithOldValueModifier<Value: Equatable>: ViewModifier {
    @State private var oldValue: Value
    let value: Value
    let perform: (_ oldValue: Value, _ newValue: Value) -> Void

    init(value: Value, perform: @escaping (_ oldValue: Value, _ newValue: Value) -> Void) {
        self._oldValue = State(initialValue: value)
        self.value = value
        self.perform = perform
    }

    func body(content: Content) -> some View {
        content
            .onChange(of: value) { newValue in
                let previous = oldValue
                oldValue = newValue
                perform(previous, newValue)
            }
    }
}
