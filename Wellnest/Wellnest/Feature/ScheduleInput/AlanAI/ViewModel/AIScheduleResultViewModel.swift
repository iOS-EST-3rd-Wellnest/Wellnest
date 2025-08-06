//
//  AIScheduleResultViewModel.swift
//  Wellnest
//
//  Created by junil on 8/6/25.
//

import Foundation

@MainActor
final class AIScheduleResultViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var showRawResponse = false
    
    // MARK: - Properties
    let healthPlan: HealthPlanResponse?
    let isLoading: Bool
    let errorMessage: String
    let rawResponse: String
    
    // MARK: - Computed Properties
    var shouldShowRawResponseButton: Bool {
        !errorMessage.isEmpty && !rawResponse.isEmpty
    }
    
    var currentViewState: ViewState {
        if isLoading {
            return .loading
        } else if !errorMessage.isEmpty {
            return .error
        } else if healthPlan != nil {
            return .content
        } else {
            return .empty
        }
    }
    
    // MARK: - Initialization
    init(
        healthPlan: HealthPlanResponse?,
        isLoading: Bool,
        errorMessage: String,
        rawResponse: String
    ) {
        self.healthPlan = healthPlan
        self.isLoading = isLoading
        self.errorMessage = errorMessage
        self.rawResponse = rawResponse
    }
    
    // MARK: - Public Methods
    func showRawResponseSheet() {
        showRawResponse = true
    }
    
    // MARK: - View State Enum
    enum ViewState {
        case loading
        case error
        case content
        case empty
    }
}
