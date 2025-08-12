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
}
