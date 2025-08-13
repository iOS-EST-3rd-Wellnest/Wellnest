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
    @Published var activityPreferences: [ActivityPreference] = ActivityPreference.activities
    @Published var preferredTimeSlots: [PreferredTimeSlot] = PreferredTimeSlot.timeSlots
    @Published var weatherPreferences: [WeatherPreference] = WeatherPreference.weathers
    @Published var healthConditions: [HealthCondition] = HealthCondition.conditions


    private let context = CoreDataService.shared.context

    init() {
        fetchOrCreateUserInfo()
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

//    func toggleActivity(_ activity: ActivityPreference) {
//        if let index = activityPreferences.firstIndex(where: { $0.id == activity.id }) {
//            activityPreferences[index].isSelected.toggle()
//            saveActivityPreferences()
//        }
//    }
//
//    func saveActivityPreferences() {
//        let selected = activityPreferences.filter { $0.isSelected }
//        if selected.contains(where: { $0.title == "특별히 없음" }) {
//            userEntity?.activityPreferences = nil
//        } else {
//            userEntity?.activityPreferences = selected.map { $0.title }.joined(separator: ", ")
//        }
//        try? CoreDataService.shared.saveContext()
//    }
}
