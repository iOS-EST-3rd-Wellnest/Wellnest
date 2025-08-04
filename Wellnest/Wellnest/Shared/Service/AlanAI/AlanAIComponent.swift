//
//  AlanAIComponent.swift
//  Wellnest
//
//  Created by junil on 7/31/25.
//

import Foundation
import Combine

// MARK: - API Models
struct APIResponse: Codable {
    let action: ActionInfo
    let content: String
}

struct ActionInfo: Codable {
    let name: String
    let speak: String
}

// MARK: - Alan AI Service
class AlanAIService: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var response: String = ""
    @Published var errorMessage: String = ""

    private let apiURL = "https://kdt-api-function.azurewebsites.net/api/v1/question"
    private let clientID: String

    init() {
        // Info.plist에서 클라이언트 ID 읽기
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let clientID = plist["ALAN_CLIENT_ID"] as? String {
            self.clientID = clientID
        } else {
            self.clientID = ""
            print("⚠️ ALAN_CLIENT_ID를 Info.plist에서 찾을 수 없습니다.")
        }
    }

    func sendHealthPlanRequest(_ userRequest: String) {
        guard !userRequest.isEmpty else { return }

        resetState()
        isLoading = true

        let fullPrompt = createHealthPlanPrompt(userRequest: userRequest)

        guard var urlComponents = URLComponents(string: apiURL) else {
            handleError("잘못된 URL입니다.")
            return
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "content", value: fullPrompt),
            URLQueryItem(name: "client_id", value: clientID)
        ]

        guard let url = urlComponents.url else {
            handleError("URL 생성에 실패했습니다.")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.handleAPIResponse(data: data, response: response, error: error)
            }
        }.resume()
    }

    private func resetState() {
        response = ""
        errorMessage = ""
    }

    private func handleError(_ message: String) {
        isLoading = false
        errorMessage = message
    }

    private func handleAPIResponse(data: Data?, response: URLResponse?, error: Error?) {
        isLoading = false

        if let error = error {
            errorMessage = "네트워크 오류: \(error.localizedDescription)"
            return
        }

        guard let data = data else {
            errorMessage = "데이터를 받지 못했습니다."
            return
        }

        do {
            let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
            self.response = apiResponse.content
        } catch {
            errorMessage = "응답 파싱 오류: \(error.localizedDescription)"
        }
    }

    private func createHealthPlanPrompt(userRequest: String) -> String {
        return """
        건강 플래너 AI 프롬프트
        
        시스템 역할 정의:
        당신은 전문 건강 및 피트니스 플래너 AI입니다. 사용자의 개인 정보를 바탕으로 과학적이고 실현 가능한 맞춤형 건강 계획을 수립해주세요.
        
        사용자 정보:
        - 성별: 남성
        - 나이: 25세
        - 키: 180cm
        - 몸무게: 90kg
        - 수면시간: 오전 12시 ~ 오전 7시 (7시간)
        - 운동 가능시간: 오후 8시 ~ 오후 11시 (3시간 중)
        - 선호 운동: 유산소/근력운동/요가/필라테스/수영/사이클링
        - 운동 강도: 보통 (사용자 요청에 따라 조절)
        
        사용자 요청: \(userRequest)
        일정이나 루틴에 관한 요청이 아닐 시 재작성 요청을 출력해주세요.
        
        출력 형식:
        요일별 운동일정을 JSON 형식으로 응답해주세요.
        
        JSON 예시:
        
        
        위 정보를 바탕으로 구체적이고 실행 가능한 건강 플랜을 작성해주세요.
        """
    }
}

// MARK: - User Profile Model (확장 가능)
struct UserProfile {
    let gender: String
    let age: Int
    let height: Int
    let weight: Int
    let sleepSchedule: String
    let exerciseTimeSlot: String
    let preferredExercises: [String]
    let exerciseIntensity: String

    static let `default` = UserProfile(
        gender: "남성",
        age: 25,
        height: 180,
        weight: 90,
        sleepSchedule: "오전 12시 ~ 오전 7시 (7시간)",
        exerciseTimeSlot: "오후 8시 ~ 오후 11시 (3시간 중)",
        preferredExercises: ["유산소", "근력운동", "요가", "필라테스", "수영", "사이클링"],
        exerciseIntensity: "보통"
    )
}
