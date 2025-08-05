//
//  AlanPromptBuilder.swift
//  Wellnest
//
//  Created by junil on 8/4/25.
//

import Foundation

struct AlanPromptBuilder {
    static func buildPrompt(from request: PlanRequest, userProfile: UserProfile) -> String {
        return request.toPrompt(userProfile: userProfile)
    }
}
