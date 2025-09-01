//
//  AlanAIService.swift
//  Wellnest
//
//  Created by junil on 8/4/25.
//

import Foundation
import Combine
import FirebaseCrashlytics

final class AlanAIService: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var rawResponse: String = ""
    @Published var healthPlan: HealthPlanResponse?

    let clientID: String
    private let networkManager = NetworkManager.shared
    let logger: CrashLogger

    init(logger: CrashLogger = CrashlyticsLogger()) {
        self.logger = logger
        
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let clientID = plist["ALAN_CLIENT_ID"] as? String {
            self.clientID = clientID
            logger.log("AlanAIService: Secrets loaded (clientID length=\(clientID.count))")
        } else {
            self.clientID = ""
            logger.log("AlanAIService: ALAN_CLIENT_ID not found")
            logger.record(NSError(domain: "AlanAIService", code: 9101,
                               userInfo: [NSLocalizedDescriptionKey: "ALAN_CLIENT_ID missing"]),
                          userInfo: nil)
        }
    }

    func requestString(prompt: String) async throws -> String {
        await MainActor.run {
            isLoading = true
            resetState()
        }

        guard !clientID.isEmpty else {
            await MainActor.run {
                isLoading = false
            }
            let err = NSError(domain: "AlanAIService", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "Client ID가 없습니다."])
            logger.record(err, userInfo: ["phase": "precondition"])
            throw err
        }

        logger.set(prompt.count, forKey: "alan.prompt.length")
        logger.set(Self.shortHash(prompt), forKey: "alan.prompt.hash")
        logger.log("AlanAIService.requestString start")

        do {
            let content = try await networkManager.requestString(
                url: "https://kdt-api-function.azurewebsites.net/api/v1/question",
                parameters: [
                    "content": prompt,
                    "client_id": clientID
                ]
            )

            await MainActor.run {
                isLoading = false
                rawResponse = content
            }

            logger.log("AlanAIService.requestString success (len=\(content.count))")
            return content

        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
            logger.record(error, userInfo: [
                 "endpoint": "/api/v1/question",
                 "phase": "requestString"
             ])
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
            logger.record(error, userInfo: [
                           "phase": "jsonExtract",
                           "content.len": content.count])
            throw error
        }

        guard let jsonData = validJSONString.data(using: .utf8) else {
            let error = NSError(domain: "AlanAIService", code: -3, userInfo: [NSLocalizedDescriptionKey: "JSON 데이터 변환 실패"])
            logger.record(error, userInfo: ["phase": "jsonDataConvert"])
            throw error
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decodedObject = try decoder.decode(T.self, from: jsonData)
            logger.log("AlanAIService.parseResponse success (type=\(String(describing: T.self)))")
            print("JSON 파싱 성공")
            return decodedObject
        } catch {
            logger.record(error, userInfo: [
                       "phase": "jsonDecode",
                       "type": String(describing: T.self),
                       "json.len": validJSONString.count
            ])
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

    /// 프롬프트 원문을 남기지 않기 위한 짧은 해시
    static func shortHash(_ text: String) -> String {
        // 간단한 해싱(보안 목적 X, 로깅 식별용)
        let s = text.utf8.reduce(UInt64(1469598103934665603)) { (h, b) in
            (h ^ UInt64(b)) &* 1099511628211
        }
        return String(format: "%016llx", s)
    }
}
