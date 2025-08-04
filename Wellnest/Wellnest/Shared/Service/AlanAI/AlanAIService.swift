//
//  AlanAIService.swift
//  Wellnest
//
//  Created by junil on 8/4/25.
//

import Foundation
import Combine

// MARK: - Enhanced Alan AI Service
class AlanAIService: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var healthPlan: HealthPlanResponse?
    @Published var errorMessage: String = ""
    @Published var rawResponse: String = ""

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

    func generateHealthPlan(_ request: PlanRequest, userProfile: UserProfile = .default) {
        resetState()
        isLoading = true

        // Client ID가 없으면 테스트 데이터 생성
        if clientID.isEmpty {
            print("⚠️ Client ID가 없어 테스트 데이터를 생성합니다.")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.generateTestHealthPlan(request)
            }
            return
        }

        let prompt = request.toPrompt(userProfile: userProfile)

        // Client ID 확인
        print("🔑 Client ID: \(clientID.isEmpty ? "없음" : "있음 (\(clientID.prefix(8))...)")")

        guard var urlComponents = URLComponents(string: apiURL) else {
            handleError("잘못된 URL입니다.")
            return
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "content", value: prompt),
            URLQueryItem(name: "client_id", value: clientID)
        ]

        guard let url = urlComponents.url else {
            handleError("URL 생성에 실패했습니다.")
            return
        }

        print("🌐 요청 URL: \(url)")

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.handleAPIResponse(data: data, response: response, error: error)
            }
        }.resume()
    }

    // MARK: - Test Data Generation
    private func generateTestHealthPlan(_ request: PlanRequest) {
        isLoading = false

        let testResponse = createTestHealthPlan(for: request)
        self.healthPlan = testResponse

        print("✅ 테스트 플랜 생성 완료!")
    }

    private func createTestHealthPlan(for request: PlanRequest) -> HealthPlanResponse {
        let schedules: [AIScheduleItem]

        switch request.planType {
        case .single:
            schedules = [
                AIScheduleItem(
                    day: nil,
                    date: "2025-08-01",
                    time: "20:00-21:00",
                    activity: "전신 근력 운동",
                    duration: "60분",
                    intensity: request.intensity,
                    location: "헬스장",
                    notes: "워밍업 10분 포함"
                )
            ]
        case .multiple:
            schedules = [
                AIScheduleItem(
                    day: nil,
                    date: "2025-08-01",
                    time: "20:00-21:00",
                    activity: "유산소 운동",
                    duration: "60분",
                    intensity: request.intensity,
                    location: "헬스장",
                    notes: "트레드밀 또는 사이클"
                ),
                AIScheduleItem(
                    day: nil,
                    date: "2025-08-03",
                    time: "20:00-21:00",
                    activity: "근력 운동",
                    duration: "60분",
                    intensity: request.intensity,
                    location: "헬스장",
                    notes: "상체 중심 운동"
                )
            ]
        case .routine:
            schedules = [
                AIScheduleItem(
                    day: "월요일",
                    date: nil,
                    time: "20:00-21:00",
                    activity: "상체 근력 운동",
                    duration: "60분",
                    intensity: request.intensity,
                    location: "헬스장",
                    notes: "가슴, 어깨, 팔 중심"
                ),
                AIScheduleItem(
                    day: "수요일",
                    date: nil,
                    time: "20:00-21:00",
                    activity: "하체 근력 운동",
                    duration: "60분",
                    intensity: request.intensity,
                    location: "헬스장",
                    notes: "다리, 엉덩이 중심"
                ),
                AIScheduleItem(
                    day: "금요일",
                    date: nil,
                    time: "20:00-21:00",
                    activity: "유산소 운동",
                    duration: "60분",
                    intensity: request.intensity,
                    location: "헬스장",
                    notes: "런닝 또는 사이클"
                )
            ]
        }

        let resources = ResourceInfo(
            equipment: ["덤벨", "바벨", "벤치"],
            videos: [
                VideoResource(
                    title: "초보자를 위한 헬스장 운동법",
                    url: "https://youtube.com/watch?v=example",
                    thumbnail: "https://img.youtube.com/vi/example/0.jpg",
                    duration: "15분"
                )
            ],
            locations: [
                LocationResource(
                    name: "피트니스24 강남점",
                    address: "서울시 강남구",
                    type: "gym",
                    rating: 4.5
                )
            ],
            products: [
                ProductResource(
                    name: "웨이 프로틴 파우더",
                    category: "보충제",
                    price: "45,000원",
                    link: "https://example.com/protein"
                )
            ]
        )

        return HealthPlanResponse(
            planType: request.planType.rawValue,
            title: "\(request.planType.displayName) 맞춤 건강 계획",
            description: "당신의 목표 달성을 위한 체계적인 운동 프로그램입니다.",
            schedules: schedules,
            resources: resources
        )
    }

    private func resetState() {
        healthPlan = nil
        errorMessage = ""
        rawResponse = ""
    }

    private func handleError(_ message: String) {
        isLoading = false
        errorMessage = message
    }

    private func handleAPIResponse(data: Data?, response: URLResponse?, error: Error?) {
        isLoading = false

        // HTTP 응답 상태 확인
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 HTTP Status: \(httpResponse.statusCode)")
            print("📡 HTTP Headers: \(httpResponse.allHeaderFields)")
        }

        if let error = error {
            errorMessage = "네트워크 오류: \(error.localizedDescription)"
            return
        }

        guard let data = data else {
            errorMessage = "데이터를 받지 못했습니다."
            return
        }

        // 먼저 원본 데이터를 문자열로 확인
        if let rawString = String(data: data, encoding: .utf8) {
            print("🔍 API 원본 응답 데이터:")
            print(rawString)
            print("==================")
            rawResponse = rawString

            // 권한 오류 체크
            if rawString.contains("권한이 없습니다") || rawString.contains("unauthorized") {
                errorMessage = "API 접근 권한이 없습니다. ALAN_CLIENT_ID를 확인해주세요."
                return
            }

            // 간단한 JSON 메시지 체크
            if rawString.contains("\"message\"") && !rawString.contains("plan_type") {
                do {
                    if let jsonData = rawString.data(using: .utf8),
                       let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                       let message = json["message"] as? String {
                        errorMessage = "API 오류: \(message)"
                        return
                    }
                } catch {
                    print("JSON 메시지 파싱 실패: \(error)")
                }
            }
        }

        do {
            // API 응답 구조 파싱 시도
            let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
            let actualContent = apiResponse.actualContent

            if !actualContent.isEmpty {
                rawResponse = actualContent
                print("🔍 AI 콘텐츠 응답:")
                print(actualContent)
                print("==================")

                // JSON 응답 파싱 시도
                parseHealthPlanFromResponse(actualContent)
            } else {
                errorMessage = "API 응답에 콘텐츠가 없습니다."
            }

        } catch {
            // API 응답 파싱 실패 시, 원본 데이터를 그대로 사용해서 JSON 파싱 시도
            print("❌ API 응답 구조 파싱 실패: \(error.localizedDescription)")

            if let rawString = String(data: data, encoding: .utf8) {
                print("원본 데이터로 직접 JSON 파싱 시도...")

                // 직접 JSON 파싱 시도
                if let jsonData = rawString.data(using: .utf8) {
                    do {
                        let healthPlanResponse = try JSONDecoder().decode(HealthPlanResponse.self, from: jsonData)
                        self.healthPlan = healthPlanResponse
                        print("✅ 직접 JSON 파싱 성공!")
                        return
                    } catch {
                        print("직접 JSON 파싱도 실패: \(error)")
                    }
                }

                // 텍스트에서 JSON 추출 시도
                parseHealthPlanFromResponse(rawString)
            } else {
                errorMessage = "API 응답을 읽을 수 없습니다: \(error.localizedDescription)"
            }
        }
    }

    private func parseHealthPlanFromResponse(_ content: String) {
        // 여러 방법으로 JSON 추출 시도
        guard let jsonString = extractJSONFromResponse(content) else {
            errorMessage = "유효한 JSON 형식을 찾을 수 없습니다."
            print("❌ JSON 추출 실패. 원본 응답:")
            print(content)
            return
        }

        print("📋 추출된 JSON:")
        print(jsonString)
        print("==================")

        // JSON 파싱
        guard let jsonData = jsonString.data(using: .utf8) else {
            errorMessage = "JSON 데이터 변환 실패"
            return
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let healthPlanResponse = try decoder.decode(HealthPlanResponse.self, from: jsonData)
            self.healthPlan = healthPlanResponse
            print("✅ JSON 파싱 성공!")

        } catch {
            errorMessage = "건강 계획 파싱 오류: \(error.localizedDescription)"
            print("❌ JSON 파싱 실패:")
            print("오류: \(error)")
            if let decodingError = error as? DecodingError {
                print("디코딩 오류 상세:")
                switch decodingError {
                case .typeMismatch(let type, let context):
                    print("타입 불일치: \(type), 경로: \(context.codingPath)")
                case .valueNotFound(let type, let context):
                    print("값 없음: \(type), 경로: \(context.codingPath)")
                case .keyNotFound(let key, let context):
                    print("키 없음: \(key), 경로: \(context.codingPath)")
                case .dataCorrupted(let context):
                    print("데이터 손상: \(context)")
                @unknown default:
                    print("알 수 없는 디코딩 오류")
                }
            }
            print("파싱 실패한 JSON: \(jsonString)")
        }
    }

    private func extractJSONFromResponse(_ response: String) -> String? {
        // 방법 1: 중괄호로 감싸진 JSON 찾기
        if let jsonString = extractJSONByBraces(response) {
            return jsonString
        }

        // 방법 2: ```json 코드 블록 찾기
        if let jsonString = extractJSONFromCodeBlock(response) {
            return jsonString
        }

        // 방법 3: plan_type이 포함된 JSON 찾기
        if let jsonString = extractJSONByKeyword(response, keyword: "plan_type") {
            return jsonString
        }

        return nil
    }

    private func extractJSONByBraces(_ response: String) -> String? {
        // 첫 번째 { 부터 마지막 } 까지 찾기
        guard let startIndex = response.firstIndex(of: "{"),
              let endIndex = response.lastIndex(of: "}") else {
            return nil
        }

        let jsonString = String(response[startIndex...endIndex])

        // 기본적인 JSON 유효성 검사
        if jsonString.contains("plan_type") && jsonString.contains("schedules") {
            return jsonString
        }

        return nil
    }

    private func extractJSONFromCodeBlock(_ response: String) -> String? {
        let patterns = [
            "```json\\s*\\n([\\s\\S]*?)\\n```",
            "```\\s*\\n([\\s\\S]*?)\\n```"
        ]

        for pattern in patterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [])
                let range = NSRange(response.startIndex..., in: response)

                if let match = regex.firstMatch(in: response, options: [], range: range) {
                    if let jsonRange = Range(match.range(at: 1), in: response) {
                        let jsonString = String(response[jsonRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                        if jsonString.contains("plan_type") {
                            return jsonString
                        }
                    }
                }
            } catch {
                continue
            }
        }

        return nil
    }

    private func extractJSONByKeyword(_ response: String, keyword: String) -> String? {
        // keyword가 포함된 라인부터 시작해서 JSON 추출
        let lines = response.components(separatedBy: .newlines)
        var startIndex = -1

        for (index, line) in lines.enumerated() {
            if line.contains(keyword) && line.contains("{") {
                startIndex = index
                break
            }
        }

        guard startIndex >= 0 else { return nil }

        var braceCount = 0
        var jsonLines: [String] = []
        var foundStart = false

        for i in startIndex..<lines.count {
            let line = lines[i]

            for char in line {
                if char == "{" {
                    braceCount += 1
                    foundStart = true
                } else if char == "}" {
                    braceCount -= 1
                }
            }

            if foundStart {
                jsonLines.append(line)
            }

            if foundStart && braceCount == 0 {
                break
            }
        }

        let jsonString = jsonLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return jsonString.isEmpty ? nil : jsonString
    }
}

// MARK: - Flexible API Models
struct APIResponse: Codable {
    let action: ActionInfo?
    let content: String?
    let data: String?
    let result: String?
    let response: String?

    // 여러 가능한 필드에서 실제 콘텐츠 추출
    var actualContent: String {
        return content ?? data ?? result ?? response ?? ""
    }
}

struct ActionInfo: Codable {
    let name: String?
    let speak: String?
}
