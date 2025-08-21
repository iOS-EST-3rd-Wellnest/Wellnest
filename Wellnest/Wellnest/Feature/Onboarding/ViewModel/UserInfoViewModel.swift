//
//  OnboardingViewModel.swift
//  Wellnest
//
//  Created by 정소이 on 8/6/25.
//

import Foundation
import CoreData

enum ScreenContext {
    case onboarding
    case settings
}

class UserInfoViewModel: ObservableObject {
    @Published var screenContext: ScreenContext = .onboarding

    @Published var userEntity: UserEntity?

    @Published var wellnessGoals: [WellnessGoal] = WellnessGoal.goals
    @Published var activityPreferences: [ActivityPreference] = []
    @Published var preferredTimeSlots: [PreferredTimeSlot] = PreferredTimeSlot.timeSlots
    @Published var weatherPreferences: [WeatherPreference] = WeatherPreference.weathers
    @Published var healthConditions: [HealthCondition] = HealthCondition.conditions

    private let context = CoreDataService.shared.context

    init() {
        fetchOrCreateUserInfo()
        loadWellnessGoals()
        loadActivities()
        loadPreferredTimeSlots()
        loadWeatherPreferences()
        loadHealthConditions()
    }

    /// 웰니스 목표 로드
    func loadWellnessGoals() {
        wellnessGoals = restoreSelection(
            items: WellnessGoal.goals,
            savedString: userEntity?.goal
        )
    }

    /// 성별에 따른 선호 활동 로드
    func loadActivities() {
        let gender = userEntity?.gender ?? "여성"
        let activitiesForGender = ActivityPreference.activities(for: gender)

        activityPreferences = restoreSelection(
            items: activitiesForGender,
            savedString: userEntity?.activityPreferences
        )
    }

    /// 선호 시간 로드
    func loadPreferredTimeSlots() {
        preferredTimeSlots = restoreSelection(
            items: PreferredTimeSlot.timeSlots,
            savedString: userEntity?.preferredTimeSlot
        )
    }

    /// 선호 날씨 로드
    func loadWeatherPreferences() {
        weatherPreferences = restoreSelection(
            items: WeatherPreference.weathers,
            savedString: userEntity?.weatherPreferences
        )
    }

    /// 건강 상태 로드
    func loadHealthConditions() {
        healthConditions = restoreSelection(
            items: HealthCondition.conditions,
            savedString: userEntity?.healthConditions
        )
    }

    /// CoreData에서 현재 사용자의 정보(UserEntity)를 가져오거나, 없으면 생성
    private func fetchOrCreateUserInfo() {
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        request.fetchLimit = 1

        let results = try? context.fetch(request)
        if let existing = results?.first {
            userEntity = existing
        } else {
            let newUserInfo = UserEntity(context: context)
            newUserInfo.id = UUID()
            newUserInfo.createdAt = Date()
            newUserInfo.nickname = ""
            newUserInfo.ageRange = ""
            newUserInfo.gender = ""
            userEntity = newUserInfo

            try? CoreDataService.shared.saveContext()
        }
    }

    /// CoreData에 저장된 카드 선택 상태 불러오기
    func restoreSelection<Item: SelectableItem>(items: [Item], savedString: String?) -> [Item] {
        guard let saved = savedString, !saved.isEmpty else {
            return items.map {
                var item = $0
                if screenContext == .settings && item.title == "특별히 없음" {
                    item.isSelected = true
                } else {
                    item.isSelected = false
                }
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
