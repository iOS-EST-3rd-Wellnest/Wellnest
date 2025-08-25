//
//  NetworkManager.swift
//  Wellnest
//
//  Created by junil on 8/4/25.
//

import Foundation

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

enum HTTPStatusCategory {
    case informational  // 100-199
    case success        // 200-299
    case redirection    // 300-399
    case clientError    // 400-499
    case serverError    // 500-599
    case unknown        // 기타
}

/**
 * NetworkManager - 범용 네트워킹 클래스
 *
 * RESTful API와의 통신을 위한 범용 네트워킹 매니저
 * JSON 응답과 문자열 응답을 모두 지원하며, 모든 HTTP 메소드를 지원
 * Swift Concurrency (async/await)를 활용하여 구현
 *
 * 주요 기능:
 * - Decodable 프로토콜을 이용한 JSON 자동 디코딩
 * - 문자열 응답 처리
 * - URL 파라미터 자동 인코딩
 * - 커스텀 헤더 지원
 * - 상세한 에러 핸들링 및 로깅
 * - HTTP 상태 코드별 세분화된 처리
 * - Swift Concurrency 지원 (async/await)
 */
final class NetworkManager {
    static let shared = NetworkManager()

    enum NetworkError: Error {
        case invalidURL
        case noData
        case decodingError(Error)
        case informationalError(Int, String?)    // 100-199
        case redirectionError(Int, String?)      // 300-399
        case clientError(Int, String?)           // 400-499
        case serverError(Int, String?)           // 500-599
        case unknownHTTPError(Int, String?)      // 기타

        var localizedDescription: String {
            switch self {
            case .invalidURL:
                return "잘못된 URL입니다."
            case .noData:
                return "데이터가 없습니다."
            case .decodingError(let error):
                return "데이터 디코딩에 실패했습니다: \(error.localizedDescription)"
            case .informationalError(let code, let message):
                return "정보 응답 (\(code)): \(message ?? "알 수 없는 정보 응답")"
            case .redirectionError(let code, let message):
                return "리다이렉션 오류 (\(code)): \(message ?? "리다이렉션이 필요합니다")"
            case .clientError(let code, let message):
                return "클라이언트 오류 (\(code)): \(message ?? Self.getClientErrorMessage(code))"
            case .serverError(let code, let message):
                return "서버 오류 (\(code)): \(message ?? Self.getServerErrorMessage(code))"
            case .unknownHTTPError(let code, let message):
                return "알 수 없는 HTTP 오류 (\(code)): \(message ?? "알 수 없는 오류")"
            }
        }

        var category: HTTPStatusCategory {
            switch self {
            case .informationalError:
                return .informational
            case .redirectionError:
                return .redirection
            case .clientError:
                return .clientError
            case .serverError:
                return .serverError
            case .unknownHTTPError:
                return .unknown
            default:
                return .unknown
            }
        }

        private static func getClientErrorMessage(_ code: Int) -> String {
            switch code {
            case 400: return "잘못된 요청"
            case 401: return "인증이 필요합니다"
            case 403: return "접근이 금지되었습니다"
            case 404: return "리소스를 찾을 수 없습니다"
            case 405: return "허용되지 않는 메소드"
            case 408: return "요청 시간 초과"
            case 429: return "너무 많은 요청"
            default: return "클라이언트 오류"
            }
        }

        private static func getServerErrorMessage(_ code: Int) -> String {
            switch code {
            case 500: return "내부 서버 오류"
            case 502: return "잘못된 게이트웨이"
            case 503: return "서비스를 사용할 수 없습니다"
            case 504: return "게이트웨이 시간 초과"
            default: return "서버 오류"
            }
        }
    }

    private init() {}

    /**
     * 범용 네트워크 요청 메소드 (JSON 응답용) - async/await 버전
     *
     * Decodable 프로토콜을 준수하는 모델로 자동 디코딩
     * Codable 대신 Decodable만 사용하여 더 명확하고 효율적
     *
     * - Parameters:
     *   - url: 요청할 URL 문자열
     *   - method: HTTP 메소드 (기본값: .GET)
     *   - parameters: URL 쿼리 파라미터 딕셔너리 (선택사항)
     *   - body: 요청 바디 데이터 (선택사항, 주로 POST/PUT에서 사용)
     *   - headers: 커스텀 HTTP 헤더 딕셔너리 (선택사항)
     *
     * - Returns: 디코딩된 응답 객체
     * - Throws: NetworkError 또는 기타 네트워크 관련 에러
     */
    func request<T: Decodable>(
        url: String,
        method: HTTPMethod = .GET,
        parameters: [String: String]? = nil,
        body: Data? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {
        guard let urlRequest = buildRequest(
            url: url,
            method: method,
            parameters: parameters,
            body: body,
            headers: headers
        ) else {
            throw NetworkError.invalidURL
        }

        let data = try await executeRequest(urlRequest)

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decodedObject = try decoder.decode(T.self, from: data)
            return decodedObject
        } catch {
            print("JSON 디코딩 실패: \(error)")
            throw NetworkError.decodingError(error)
        }
    }

    /**
     * JSON Dictionary 응답용 네트워크 요청 메소드
     *
     * 구조화되지 않은 JSON 응답을 받을 때 사용
     * Codable 모델이 없는 경우에 유용
     *
     * - Parameters: request 메소드와 동일
     * - Returns: JSON Dictionary
     * - Throws: NetworkError 또는 기타 네트워크 관련 에러
     */
    func requestJSON(
        url: String,
        method: HTTPMethod = .GET,
        parameters: [String: String]? = nil,
        body: Data? = nil,
        headers: [String: String]? = nil
    ) async throws -> [String: Any] {
        guard let urlRequest = buildRequest(
            url: url,
            method: method,
            parameters: parameters,
            body: body,
            headers: headers
        ) else {
            throw NetworkError.invalidURL
        }

        let data = try await executeRequest(urlRequest)

        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw NetworkError.decodingError(NSError(domain: "NetworkManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "JSON이 Dictionary 형태가 아닙니다."]))
            }
            return json
        } catch {
            print("JSON 파싱 실패: \(error)")
            throw NetworkError.decodingError(error)
        }
    }

    /**
     * 문자열 응답용 네트워크 요청 메소드 - async/await 버전
     *
     * JSON이 아닌 텍스트 응답을 받을 때 사용
     *
     * - Parameters:
     *   - url: 요청할 URL 문자열
     *   - method: HTTP 메소드 (기본값: .GET)
     *   - parameters: URL 쿼리 파라미터 딕셔너리 (선택사항)
     *   - body: 요청 바디 데이터 (선택사항)
     *   - headers: 커스텀 HTTP 헤더 딕셔너리 (선택사항)
     *
     * - Returns: 문자열 응답
     * - Throws: NetworkError 또는 기타 네트워크 관련 에러
     */
    func requestString(
        url: String,
        method: HTTPMethod = .GET,
        parameters: [String: String]? = nil,
        body: Data? = nil,
        headers: [String: String]? = nil
    ) async throws -> String {
        guard let urlRequest = buildRequest(
            url: url,
            method: method,
            parameters: parameters,
            body: body,
            headers: headers
        ) else {
            throw NetworkError.invalidURL
        }

        let data = try await executeRequest(urlRequest)

        guard let string = String(data: data, encoding: .utf8) else {
            print("문자열 변환 실패")
            throw NetworkError.decodingError(NSError(domain: "NetworkManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "UTF-8 문자열 변환에 실패했습니다."]))
        }

        return string
    }

    /**
     * URLRequest 객체를 생성하는 내부 메소드
     *
     * URL, 파라미터, 헤더 등을 조합하여 완전한 URLRequest를 생성
     * 쿼리 파라미터는 자동으로 URL 인코딩
     *
     * - Parameters:
     *   - url: 기본 URL 문자열
     *   - method: HTTP 메소드
     *   - parameters: 쿼리 파라미터 (자동으로 URL 인코딩됨)
     *   - body: 요청 바디
     *   - headers: HTTP 헤더
     *
     * - Returns: 구성된 URLRequest 또는 nil (URL 생성 실패 시)
     */
    private func buildRequest(
        url: String,
        method: HTTPMethod,
        parameters: [String: String]?,
        body: Data?,
        headers: [String: String]?
    ) -> URLRequest? {
        guard var components = URLComponents(string: url) else {
            print("URLComponents 생성 실패: \(url)")
            return nil
        }

        if let parameters = parameters {
            components.queryItems = parameters.compactMap { key, value in
                guard let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                    print("파라미터 인코딩 실패: \(key)=\(value)")
                    return nil
                }
                return URLQueryItem(name: key, value: encodedValue)
            }
        }

        guard let finalURL = components.url else {
            print("최종 URL 생성 실패")
            print("   - scheme: \(components.scheme ?? "nil")")
            print("   - host: \(components.host ?? "nil")")
            print("   - path: \(components.path)")
            print("   - query: \(components.query ?? "nil")")
            return nil
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = method.rawValue
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }

    /**
     * 실제 네트워크 요청을 실행하는 내부 메소드 - async/await 버전
     *
     * URLSession을 사용하여 비동기 네트워크 요청을 수행
     * Swift Concurrency를 활용하여 GCD 없이 구현
     *
     * - Parameter request: 실행할 URLRequest
     * - Returns: 응답 데이터
     * - Throws: NetworkError 또는 기타 네트워크 관련 에러
     */
    private func executeRequest(_ request: URLRequest) async throws -> Data {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                print("Status: \(httpResponse.statusCode)")

                try handleHTTPStatusCode(httpResponse.statusCode, data: data)
            }

            print("Data received: \(data.count) bytes")
            return data

        } catch let error as NetworkError {
            throw error
        } catch {
            print("Network Error: \(error.localizedDescription)")
            throw error
        }
    }

    /**
     * HTTP 상태 코드를 범주별로 처리하는 메소드
     *
     * - Parameters:
     *   - statusCode: HTTP 상태 코드
     *   - data: 응답 데이터 (에러 메시지 추출용)
     * - Throws: 상태 코드에 따른 NetworkError
     */
    private func handleHTTPStatusCode(_ statusCode: Int, data: Data) throws {
        let errorMessage = String(data: data, encoding: .utf8)

        switch statusCode {
        case 100..<200:
            // 1xx: 정보 응답 (일반적으로 에러가 아니지만 로깅용)
            print("Informational response: \(statusCode)")

        case 200..<300:
            // 2xx: 성공 응답
            print("Success: \(statusCode)")

        case 300..<400:
            // 3xx: 리다이렉션
            print("Redirection: \(statusCode) - \(errorMessage ?? "No message")")
            throw NetworkError.redirectionError(statusCode, errorMessage)

        case 400..<500:
            // 4xx: 클라이언트 오류
            print("Client Error: \(statusCode) - \(errorMessage ?? "No message")")
            throw NetworkError.clientError(statusCode, errorMessage)

        case 500..<600:
            // 5xx: 서버 오류
            print("Server Error: \(statusCode) - \(errorMessage ?? "No message")")
            throw NetworkError.serverError(statusCode, errorMessage)

        default:
            // 알 수 없는 상태 코드
            print("Unknown HTTP Status: \(statusCode) - \(errorMessage ?? "No message")")
            throw NetworkError.unknownHTTPError(statusCode, errorMessage)
        }
    }

    /**
     * HTTP 상태 코드의 범주를 반환하는 유틸리티 메소드
     *
     * - Parameter statusCode: HTTP 상태 코드
     * - Returns: 상태 코드 범주
     */
    static func getStatusCategory(_ statusCode: Int) -> HTTPStatusCategory {
        switch statusCode {
        case 100..<200: return .informational
        case 200..<300: return .success
        case 300..<400: return .redirection
        case 400..<500: return .clientError
        case 500..<600: return .serverError
        default: return .unknown
        }
    }
}
