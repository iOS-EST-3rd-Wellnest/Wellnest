//
//  PlanCompletionData.swift
//  Wellnest
//
//  Created by junil on 8/14/25.
//

import Foundation

struct PlanCompletionData {
    let completedItems: Int
    let totalItems: Int
    
    var completionRate: Double {
        guard totalItems > 0 else { return 0.0 }
        return Double(completedItems) / Double(totalItems)
    }
    
    var remainingItems: Int {
        totalItems - completedItems
    }
}
