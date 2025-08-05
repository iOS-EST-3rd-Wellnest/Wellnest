//
//  NetworkManager.swift
//  Wellnest
//
//  Created by junil on 8/4/25.
//

import Foundation

/// HTTP 메소드를 정의하는 열거형
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

/**
 * NetworkManager - 범용 네트워킹 클래스 (Swift Concurrency 버전)
 *
 * RESTful API와의 통신을 위한 범용 네트워킹 매니저입니다.
 * JSON 응답과 문자열 응답을 모두 지원하며, 모든 HTTP 메소드를 지원합니다.
 * Swift Concurrency (async/await)를 활용하여 구현되었습니다.
 *
 * 주요 기능:
 * - Codable 프로토콜을 이용한 JSON 자동 디코딩
 * - 문자열 응답 처리
 * - URL 파라미터 자동 인코딩
 * - 커스텀 헤더 지원
 * - 상세한 에러 핸들링 및 로깅
 * - Swift Concurrency 지원 (async/await)
 */
final class NetworkManager {
    /// 싱글톤 인스턴스
    static let shared = NetworkManager()

    /// 네트워크 관련 에러 타입
    enum NetworkError: Error {
        case invalidURL              // 잘못된 URL
        case noData                 // 응답 데이터 없음
        case decodingError          // JSON 디코딩 실패
        case httpError(Int, String?) // HTTP 상태 코드 에러 (400~599)

        var localizedDescription: String {
            switch self {
            case .invalidURL:
                return "잘못된 URL입니다."
            case .noData:
                return "데이터가 없습니다."
            case .decodingError:
                return "데이터 디코딩에 실패했습니다."
            case .httpError(let code, let message):
                return "HTTP 오류 (\(code)): \(message ?? "알 수 없는 오류")"
            }
        }
    }

    private init() {}

    /**
     * 범용 네트워크 요청 메소드 (JSON 응답용) - async/await 버전
     *
     * Codable 프로토콜을 준수하는 모델로 자동 디코딩됩니다.
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
    func request<T: Codable>(
        url: String,
        method: HTTPMethod = .GET,
        parameters: [String: String]? = nil,
        body: Data? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {
        // URLRequest 생성
        guard let urlRequest = buildRequest(
            url: url,
            method: method,
            parameters: parameters,
            body: body,
            headers: headers
        ) else {
            throw NetworkError.invalidURL
        }

        // 네트워크 요청 실행 및 JSON 디코딩
        let data = try await executeRequest(urlRequest)

        do {
            let decodedObject = try JSONDecoder().decode(T.self, from: data)
            return decodedObject
        } catch {
            print("❌ JSON 디코딩 실패: \(error)")
            throw NetworkError.decodingError
        }
    }

    /**
     * 문자열 응답용 네트워크 요청 메소드 - async/await 버전
     *
     * JSON이 아닌 텍스트 응답을 받을 때 사용합니다.
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
        // URLRequest 생성
        guard let urlRequest = buildRequest(
            url: url,
            method: method,
            parameters: parameters,
            body: body,
            headers: headers
        ) else {
            throw NetworkError.invalidURL
        }

        // 네트워크 요청 실행 및 문자열 변환
        let data = try await executeRequest(urlRequest)

        guard let string = String(data: data, encoding: .utf8) else {
            print("❌ 문자열 변환 실패")
            throw NetworkError.decodingError
        }

        return string
    }

    /**
     * URLRequest 객체를 생성하는 내부 메소드
     *
     * URL, 파라미터, 헤더 등을 조합하여 완전한 URLRequest를 생성합니다.
     * 쿼리 파라미터는 자동으로 URL 인코딩됩니다.
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
        // URLComponents로 URL 파싱
        guard var components = URLComponents(string: url) else {
            print("❌ URLComponents 생성 실패: \(url)")
            return nil
        }

        // 쿼리 파라미터 추가 (URL 인코딩 포함)
        if let parameters = parameters {
            print("📋 Parameters: \(parameters)")
            components.queryItems = parameters.compactMap { key, value in
                // URL 인코딩 처리
                guard let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                    print("❌ 파라미터 인코딩 실패: \(key)=\(value)")
                    return nil
                }
                return URLQueryItem(name: key, value: encodedValue)
            }
        }

        // 최종 URL 생성
        guard let finalURL = components.url else {
            print("❌ 최종 URL 생성 실패")
            print("   - scheme: \(components.scheme ?? "nil")")
            print("   - host: \(components.host ?? "nil")")
            print("   - path: \(components.path)")
            print("   - query: \(components.query ?? "nil")")
            return nil
        }

        print("✅ 최종 URL: \(finalURL.absoluteString)")

        // URLRequest 구성
        var request = URLRequest(url: finalURL)
        request.httpMethod = method.rawValue
        request.httpBody = body

        // 기본 헤더 설정
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        // 커스텀 헤더 추가
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }

    /**
     * 실제 네트워크 요청을 실행하는 내부 메소드 - async/await 버전
     *
     * URLSession을 사용하여 비동기 네트워크 요청을 수행합니다.
     * Swift Concurrency를 활용하여 GCD 없이 구현되었습니다.
     *
     * - Parameter request: 실행할 URLRequest
     * - Returns: 응답 데이터
     * - Throws: NetworkError 또는 기타 네트워크 관련 에러
     */
    private func executeRequest(_ request: URLRequest) async throws -> Data {
        print("📡 Request URL: \(request.url?.absoluteString ?? "nil")")
        print("📡 Request Method: \(request.httpMethod ?? "nil")")

        do {
            // URLSession의 async/await 메소드 사용
            let (data, response) = try await URLSession.shared.data(for: request)

            // HTTP 응답 상태 코드 확인
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Status: \(httpResponse.statusCode)")

                // 4xx, 5xx 에러 처리
                if httpResponse.statusCode >= 400 {
                    let errorMessage = String(data: data, encoding: .utf8)
                    print("❌ HTTP Error: \(httpResponse.statusCode) - \(errorMessage ?? "No message")")
                    throw NetworkError.httpError(httpResponse.statusCode, errorMessage)
                }
            }

            print("✅ Data received: \(data.count) bytes")
            return data

        } catch let error as NetworkError {
            // NetworkError는 그대로 전파
            throw error
        } catch {
            // 기타 네트워크 에러 처리
            print("❌ Network Error: \(error.localizedDescription)")
            throw error
        }
    }
}
