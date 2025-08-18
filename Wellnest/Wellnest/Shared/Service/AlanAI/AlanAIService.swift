//
//  AlanAIService.swift
//  Wellnest
//
//  Created by junil on 8/4/25.
//

import Foundation
import Combine

final class AlanAIService: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var rawResponse: String = ""
    @Published var healthPlan: HealthPlanResponse?

    let clientID: String
    private let networkManager = NetworkManager.shared

    init() {
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let clientID = plist["ALAN_CLIENT_ID"] as? String {
            self.clientID = clientID
            print("Secrets.plist에서 Client ID 로드 성공 (길이: \(clientID.count))")
        } else {
            self.clientID = ""
            print("ALAN_CLIENT_ID를 Secrets.plist에서 찾을 수 없습니다.")
        }
    }

    func requestString(prompt: String) async throws -> String {
        // UI 상태 업데이트는 메인 스레드에서
        await MainActor.run {
            isLoading = true
            resetState()
        }

        guard !clientID.isEmpty else {
            await MainActor.run {
                isLoading = false
            }
            throw NSError(domain: "AlanAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Client ID가 없습니다."])
        }

        do {
            // 네트워크 작업은 백그라운드에서 실행
            let content = try await networkManager.requestString(
                url: "https://kdt-api-function.azurewebsites.net/api/v1/question",
                parameters: [
                    "content": prompt,
                    "client_id": clientID
                ]
            )

            // UI 상태 업데이트는 메인 스레드에서
            await MainActor.run {
                isLoading = false
                rawResponse = content
            }

            return content

        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
            throw error
        }
    }

    func request<T: Codable>(
        prompt: String,
        responseType: T.Type,
        jsonExtractor: ((String) -> String?)? = nil
    ) async throws -> T {
        let content = try await requestString(prompt: prompt)
        return try parseResponse(content, responseType: responseType, jsonExtractor: jsonExtractor)
    }

    func requestString(
        prompt: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        Task {
            do {
                let result = try await requestString(prompt: prompt)
                await MainActor.run {
                    completion(.success(result))
                }
            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }

    func request<T: Codable>(
        prompt: String,
        responseType: T.Type,
        jsonExtractor: ((String) -> String?)? = nil,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        Task {
            do {
                let result = try await request(prompt: prompt, responseType: responseType, jsonExtractor: jsonExtractor)
                await MainActor.run {
                    completion(.success(result))
                }
            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }

    private func resetState() {
        errorMessage = ""
        rawResponse = ""
    }

    private func parseResponse<T: Codable>(
        _ content: String,
        responseType: T.Type,
        jsonExtractor: ((String) -> String?)?
    ) throws -> T {
        let jsonString: String?

        if let customExtractor = jsonExtractor {
            jsonString = customExtractor(content)
        } else {
            jsonString = extractJSONFromResponse(content)
        }

        guard let validJSONString = jsonString else {
            let error = NSError(domain: "AlanAIService", code: -2, userInfo: [NSLocalizedDescriptionKey: "유효한 JSON 형식을 찾을 수 없습니다."])
            print("JSON 추출 실패. 원본 응답:\n\(content)")
            throw error
        }

        print("추출된 JSON:\n\(validJSONString)\n==================")

        guard let jsonData = validJSONString.data(using: .utf8) else {
            let error = NSError(domain: "AlanAIService", code: -3, userInfo: [NSLocalizedDescriptionKey: "JSON 데이터 변환 실패"])
            throw error
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decodedObject = try decoder.decode(T.self, from: jsonData)
            print("JSON 파싱 성공!")
            return decodedObject
        } catch {
            print("JSON 파싱 실패: \(error)")
            throw error
        }
    }

    func extractJSONFromResponse(_ response: String) -> String? {
        if let json = extractJSONByBraces(response) {
            return json
        }
        if let json = extractJSONFromCodeBlock(response) {
            return json
        }
        return nil
    }

    func extractJSONByBraces(_ response: String) -> String? {
        guard let start = response.firstIndex(of: "{"),
              let end = response.lastIndex(of: "}") else { return nil }
        return String(response[start...end])
    }

    func extractJSONFromCodeBlock(_ response: String) -> String? {
        let patterns = ["```json\\s*\\n([\\s\\S]*?)\\n```", "```\\s*\\n([\\s\\S]*?)\\n```"]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: response, range: NSRange(response.startIndex..., in: response)),
               let range = Range(match.range(at: 1), in: response) {
                return String(response[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return nil
    }

    func extractJSONByKeyword(_ response: String, keyword: String) -> String? {
        let lines = response.components(separatedBy: .newlines)
        var startIndex = -1
        for (i, line) in lines.enumerated() {
            if line.contains(keyword), line.contains("{") {
                startIndex = i
                break
            }
        }
        guard startIndex >= 0 else { return nil }

        var braceCount = 0, foundStart = false
        var jsonLines: [String] = []

        for i in startIndex..<lines.count {
            let line = lines[i]
            for ch in line {
                if ch == "{" { braceCount += 1; foundStart = true }
                else if ch == "}" { braceCount -= 1 }
            }
            if foundStart { jsonLines.append(line) }
            if foundStart, braceCount == 0 { break }
        }

        let json = jsonLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return json.isEmpty ? nil : json
    }
}
