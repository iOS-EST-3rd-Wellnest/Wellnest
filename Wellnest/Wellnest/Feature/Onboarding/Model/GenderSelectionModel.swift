//
//  GenderSelectionModel.swift
//  Wellnest
//
//  Created by 정소이 on 8/10/25.
//

import SwiftUI
import Combine

class GenderSelectionModel: ObservableObject {
    @Published var selectedGender: String = ""
    let genderOptions = ["여성 👩🏻", "남성 👨🏻"]
}
