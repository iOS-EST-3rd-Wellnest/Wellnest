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
 * NetworkManager - 범용 네트워킹 클래스
 *
 * RESTful API와의 통신을 위한 범용 네트워킹 매니저입니다.
 * JSON 응답과 문자열 응답을 모두 지원하며, 모든 HTTP 메소드를 지원합니다.
 *
 * 주요 기능:
 * - Codable 프로토콜을 이용한 JSON 자동 디코딩
 * - 문자열 응답 처리
 * - URL 파라미터 자동 인코딩
 * - 커스텀 헤더 지원
 * - 상세한 에러 핸들링 및 로깅
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
     * 범용 네트워크 요청 메소드 (JSON 응답용)
     *
     * Codable 프로토콜을 준수하는 모델로 자동 디코딩됩니다.
     *
     * - Parameters:
     *   - url: 요청할 URL 문자열
     *   - method: HTTP 메소드 (기본값: .GET)
     *   - parameters: URL 쿼리 파라미터 딕셔너리 (선택사항)
     *   - body: 요청 바디 데이터 (선택사항, 주로 POST/PUT에서 사용)
     *   - headers: 커스텀 HTTP 헤더 딕셔너리 (선택사항)
     *   - responseType: 응답을 디코딩할 Codable 타입
     *   - completion: 완료 콜백 (메인 스레드에서 호출됨)
     */
    func request<T: Codable>(
        url: String,
        method: HTTPMethod = .GET,
        parameters: [String: String]? = nil,
        body: Data? = nil,
        headers: [String: String]? = nil,
        responseType: T.Type,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        // URLRequest 생성
        guard let urlRequest = buildRequest(
            url: url,
            method: method,
            parameters: parameters,
            body: body,
            headers: headers
        ) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }

        // 네트워크 요청 실행 및 JSON 디코딩
        executeRequest(urlRequest) { result in
            switch result {
            case .success(let data):
                do {
                    let decodedObject = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(decodedObject))
                } catch {
                    completion(.failure(NetworkError.decodingError))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /**
     * 문자열 응답용 네트워크 요청 메소드
     *
     * JSON이 아닌 텍스트 응답을 받을 때 사용합니다.
     *
     * - Parameters:
     *   - url: 요청할 URL 문자열
     *   - method: HTTP 메소드 (기본값: .GET)
     *   - parameters: URL 쿼리 파라미터 딕셔너리 (선택사항)
     *   - body: 요청 바디 데이터 (선택사항)
     *   - headers: 커스텀 HTTP 헤더 딕셔너리 (선택사항)
     *   - completion: 완료 콜백 (메인 스레드에서 호출됨)
     */
    func requestString(
        url: String,
        method: HTTPMethod = .GET,
        parameters: [String: String]? = nil,
        body: Data? = nil,
        headers: [String: String]? = nil,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // URLRequest 생성
        guard let urlRequest = buildRequest(
            url: url,
            method: method,
            parameters: parameters,
            body: body,
            headers: headers
        ) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }

        // 네트워크 요청 실행 및 문자열 변환
        executeRequest(urlRequest) { result in
            switch result {
            case .success(let data):
                if let string = String(data: data, encoding: .utf8) {
                    completion(.success(string))
                } else {
                    completion(.failure(NetworkError.decodingError))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
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
     * 실제 네트워크 요청을 실행하는 내부 메소드
     *
     * URLSession을 사용하여 비동기 네트워크 요청을 수행합니다.
     * 응답은 메인 스레드에서 전달됩니다.
     *
     * - Parameters:
     *   - request: 실행할 URLRequest
     *   - completion: 완료 콜백 (메인 스레드에서 호출됨)
     */
    private func executeRequest(_ request: URLRequest, completion: @escaping (Result<Data, Error>) -> Void) {
        print("📡 Request URL: \(request.url?.absoluteString ?? "nil")")
        print("📡 Request Method: \(request.httpMethod ?? "nil")")

        URLSession.shared.dataTask(with: request) { data, response, error in
            // 메인 스레드에서 콜백 실행
            DispatchQueue.main.async {
                // HTTP 응답 상태 코드 확인
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 Status: \(httpResponse.statusCode)")

                    // 4xx, 5xx 에러 처리
                    if httpResponse.statusCode >= 400 {
                        let errorMessage = data.flatMap { String(data: $0, encoding: .utf8) }
                        print("❌ HTTP Error: \(httpResponse.statusCode) - \(errorMessage ?? "No message")")
                        completion(.failure(NetworkError.httpError(httpResponse.statusCode, errorMessage)))
                        return
                    }
                }

                // 네트워크 에러 확인
                if let error = error {
                    print("❌ Network Error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }

                // 데이터 존재 확인
                guard let data = data else {
                    print("❌ No Data")
                    completion(.failure(NetworkError.noData))
                    return
                }

                print("✅ Data received: \(data.count) bytes")
                completion(.success(data))
            }
        }.resume()
    }
}
