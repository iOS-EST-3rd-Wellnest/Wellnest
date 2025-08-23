//
//  SwipeHelper.swift
//  Wellnest
//
//  Created by JuYong Lee on 8/21/25.
//

import SwiftUI

enum SwipeDirection { case left, right }

final class SwipeCoordinator: ObservableObject {
    @Published var openId: UUID?
    @Published var direction: SwipeDirection?

    func onSwipe(id: UUID, direction: SwipeDirection) {
        withAnimation(.easeInOut) {
            self.openId = id
            self.direction = direction
        }
    }

    func offSwipe() {
        withAnimation(.easeInOut) {
            self.openId = nil
            self.direction = nil
        }
    }
}
