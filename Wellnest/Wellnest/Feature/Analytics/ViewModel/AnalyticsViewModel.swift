//
//  AnalyticsViewModel.swift
//  Wellnest
//
//  Created by junil on 8/14/25.
//

import Foundation

class AnalyticsViewModel: ObservableObject {
    @Published var healthData: HealthData
    
    init(healthData: HealthData = MockHealthData.sampleData) {
        self.healthData = healthData
    }
}
