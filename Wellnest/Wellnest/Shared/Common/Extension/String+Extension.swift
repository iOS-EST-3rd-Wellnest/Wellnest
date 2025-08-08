//
//  String+Extension.swift
//  Wellnest
//
//  Created by 정소이 on 8/8/25.
//

import SwiftUI

extension String {
    /// 문자열에서 영문자와 숫자만  남기고, 최대 글자 수를 제한해 반환
    /// - Parameter maxLength: 최대 글자 수
    /// - Returns: 필터링된 문자열
    func onlyLettersAndNumbers(maxLength: Int) -> String {
        self.filter { $0.isLetter || $0.isNumber }
            .prefix(maxLength)
            .description
    }

    /// 문자열에서 숫자만  남기고, 최대 글자 수를 제한해 반환
    /// - Parameter maxLength: 최대 글자 수
    /// - Returns: 필터링된 문자열
    func onlyNumbers(maxLength: Int) -> String {
        self.filter { $0.isNumber }
            .prefix(maxLength)
            .description
    }
}
