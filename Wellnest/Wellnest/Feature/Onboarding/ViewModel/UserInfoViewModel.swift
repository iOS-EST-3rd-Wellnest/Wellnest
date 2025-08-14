//
//  OnboardingViewModel.swift
//  Wellnest
//
//  Created by 정소이 on 8/6/25.
//

import Foundation
import CoreData

class UserInfoViewModel: ObservableObject {
    @Published var userEntity: UserEntity?

    @Published var wellnessGoals: [WellnessGoal] = WellnessGoal.goals
    @Published var activityPreferences: [ActivityPreference] = []
    @Published var preferredTimeSlots: [PreferredTimeSlot] = PreferredTimeSlot.timeSlots
    @Published var weatherPreferences: [WeatherPreference] = WeatherPreference.weathers
    @Published var healthConditions: [HealthCondition] = HealthCondition.conditions

    private let context = CoreDataService.shared.context

    init() {
        fetchOrCreateUserInfo()
        loadActivities()
    }

    func loadActivities() {
        // 성별에 따라 기본 아이콘 배열 세팅
        let gender = userEntity?.gender ?? "여성"
        let activitiesForGender = ActivityPreference.activities(for: gender)

        // Core Data에 저장된 선택값 반영
        activityPreferences = restoreSelection(
            items: activitiesForGender,
            savedString: userEntity?.activityPreferences
        )
    }

    private func fetchOrCreateUserInfo() {
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        request.fetchLimit = 1

        let results = try? context.fetch(request)
        if let existing = results?.first {
            userEntity = existing
        } else {
            let newUserInfo = UserEntity(context: context)
            userEntity = newUserInfo

            try? CoreDataService.shared.saveContext()
        }
    }

    func restoreSelection<Item: SelectableItem>(items: [Item], savedString: String?) -> [Item] {
        guard let saved = savedString, !saved.isEmpty else {
            return items.map {
                var item = $0
                item.isSelected = false
                return item
            }
        }

        let savedTitles = saved.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        return items.map {
            var item = $0
            item.isSelected = savedTitles.contains(item.title)
            return item
        }
    }
}
