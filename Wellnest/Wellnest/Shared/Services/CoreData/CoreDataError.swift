//
//  CoreDataError.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/1/25.
//

import Foundation

/// Core Data 작업 중 발생할 수 있는 오류를 나타내는 열거형입니다.
enum CoreDataError: Error {

    /// 데이터를 읽는 도중 발생한 오류
    case readError(any Error)

    /// 데이터를 저장하는 도중 발생한 오류
    case saveError(any Error)

    /// 데이터를 삭제하는 도중 발생한 오류
    case deleteError(any Error)
}
