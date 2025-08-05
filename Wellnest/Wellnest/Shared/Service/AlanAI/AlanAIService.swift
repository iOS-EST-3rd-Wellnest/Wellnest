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
            print("✅ Secrets.plist에서 Client ID 로드 성공 (길이: \(clientID.count))")
        } else {
            self.clientID = ""
            print("⚠️ ALAN_CLIENT_ID를 Secrets.plist에서 찾을 수 없습니다.")
        }
    }

    // MARK: - Generic Request Methods

    func requestString(
        prompt: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        isLoading = true
        resetState()

        guard !clientID.isEmpty else {
            let error = NSError(domain: "AlanAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Client ID가 없습니다."])
            DispatchQueue.main.async {
                self.isLoading = false
                completion(.failure(error))
            }
            return
        }

        networkManager.requestString(
            url: "https://kdt-api-function.azurewebsites.net/api/v1/question",
            parameters: [
                "content": prompt,
                "client_id": clientID
            ]
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false

                switch result {
                case .success(let content):
                    self?.rawResponse = content
                    completion(.success(content))
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
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
        requestString(prompt: prompt) { [weak self] result in
            switch result {
            case .success(let content):
                self?.parseResponse(content, responseType: responseType, jsonExtractor: jsonExtractor, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func resetState() {
        errorMessage = ""
        rawResponse = ""
    }

    // MARK: - Response Parsing

    private func parseResponse<T: Codable>(
        _ content: String,
        responseType: T.Type,
        jsonExtractor: ((String) -> String?)?,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        let jsonString: String?

        if let customExtractor = jsonExtractor {
            jsonString = customExtractor(content)
        } else {
            jsonString = extractJSONFromResponse(content)
        }

        guard let validJSONString = jsonString else {
            let error = NSError(domain: "AlanAIService", code: -2, userInfo: [NSLocalizedDescriptionKey: "유효한 JSON 형식을 찾을 수 없습니다."])
            print("❌ JSON 추출 실패. 원본 응답:\n\(content)")
            completion(.failure(error))
            return
        }

        print("📋 추출된 JSON:\n\(validJSONString)\n==================")

        guard let jsonData = validJSONString.data(using: .utf8) else {
            let error = NSError(domain: "AlanAIService", code: -3, userInfo: [NSLocalizedDescriptionKey: "JSON 데이터 변환 실패"])
            completion(.failure(error))
            return
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decodedObject = try decoder.decode(T.self, from: jsonData)
            print("✅ JSON 파싱 성공!")
            completion(.success(decodedObject))
        } catch {
            print("❌ JSON 파싱 실패: \(error)")
            completion(.failure(error))
        }
    }

    // MARK: - JSON Extraction Methods (Internal for extensions)

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
