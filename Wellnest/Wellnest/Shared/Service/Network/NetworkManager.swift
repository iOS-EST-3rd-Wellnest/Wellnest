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

final class NetworkManager {
    static let shared = NetworkManager()

    enum NetworkError: Error {
        case invalidURL
        case noData
        case decodingError
        case httpError(Int, String?)

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

    func request<T: Codable>(
        url: String,
        method: HTTPMethod = .GET,
        parameters: [String: String]? = nil,
        body: Data? = nil,
        headers: [String: String]? = nil,
        responseType: T.Type,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
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

    func requestString(
        url: String,
        method: HTTPMethod = .GET,
        parameters: [String: String]? = nil,
        body: Data? = nil,
        headers: [String: String]? = nil,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
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

    private func buildRequest(
        url: String,
        method: HTTPMethod,
        parameters: [String: String]?,
        body: Data?,
        headers: [String: String]?
    ) -> URLRequest? {
        guard var components = URLComponents(string: url) else {
            print("❌ URLComponents 생성 실패: \(url)")
            return nil
        }

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

        guard let finalURL = components.url else {
            print("❌ 최종 URL 생성 실패")
            print("   - scheme: \(components.scheme ?? "nil")")
            print("   - host: \(components.host ?? "nil")")
            print("   - path: \(components.path)")
            print("   - query: \(components.query ?? "nil")")
            return nil
        }

        print("✅ 최종 URL: \(finalURL.absoluteString)")

        var request = URLRequest(url: finalURL)
        request.httpMethod = method.rawValue
        request.httpBody = body

        // 기본 헤더
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        // 커스텀 헤더
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }

    private func executeRequest(_ request: URLRequest, completion: @escaping (Result<Data, Error>) -> Void) {
        print("📡 Request URL: \(request.url?.absoluteString ?? "nil")")
        print("📡 Request Method: \(request.httpMethod ?? "nil")")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 Status: \(httpResponse.statusCode)")

                    if httpResponse.statusCode >= 400 {
                        let errorMessage = data.flatMap { String(data: $0, encoding: .utf8) }
                        print("❌ HTTP Error: \(httpResponse.statusCode) - \(errorMessage ?? "No message")")
                        completion(.failure(NetworkError.httpError(httpResponse.statusCode, errorMessage)))
                        return
                    }
                }

                if let error = error {
                    print("❌ Network Error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }

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
