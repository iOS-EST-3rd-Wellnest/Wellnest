//
//  HomeViewModel.swift
//  Wellnest
//
//  Created by JuYong Lee on 8/6/25.
//

import Foundation
import UIKit

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var quoteOfTheDay: String?
    
    @Published var currentWeather: WeatherItem?
    @Published var forecastWeather = [WeatherItem]()
    
    @Published var videoList = [VideoRecommendModel]()
    
    private let alanService = AlanAIService()
    private let weatherService = WeatherService()
    private let locationManager = LocationManager()
    
    private var prompt = RecommendPrompt()
    
    // 프리패치 작업 취소를 위해 핸들 보관
    private var prefetchTasks = [Task<Void, Never>]()
    
    // MARK: - 오늘의 한마디
    func quoteOfTheDayRequest() {
        Task {
            do {
                quoteOfTheDay = try await alanService.requestString(prompt: prompt.quoteOfTheDayPrompt())
                
                print("오늘의 한마디:", quoteOfTheDay)
            } catch {
                print("❌ 오늘의 한마디 요청 실패:", error.localizedDescription)
            }
        }
    }
    
    // MARK: - 날씨
    func weatherRequest() {
        Task {
            do {
                let location = try await locationManager.requestLocation()
                let lat = location.coordinate.latitude
                let lon = location.coordinate.longitude
                
                self.currentWeather = try await weatherService.fetchCurrentWeather(lat: lat, lon: lon)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Alan Ai를 활용한 추천 영상 Youtube 검색
    func videoRequest() {
        Task {
            do {
                let response = try await alanService.requestString(prompt: prompt.videoPrompt())
                let keywords = extractContent(from: response)
                print(keywords)
                
                if let items = try await fetchVideoList(keywords: keywords) {
                    let models = items.map { item in
                        VideoRecommendModel(
                            id: item.id.videoID,
                            title: htmlDecoded(from: item.snippet.title),
                            thumbnail: item.snippet.thumbnails.medium.url
                        )
                    }
                    self.videoList = models
                    
                    // 썸네일 프리패치
                    prefetchThumbnails(for: models)
                }
            } catch {
                print("❌ 동영상 불러오기 실패:", error.localizedDescription)
            }
        }
    }
    
    private func fetchUserInfo() {
        
    }
    
    private func createDailySummary() {
        
    }
    
    private func updateDailySummary() {
        
    }
    
    /// Youtube API를 활용한 추천 영상 목록 검색
    /// - Parameter keywords: 자연어 형태의 검색어
    /// - Returns: 영상 목록으로 Item 배열을 반환
    private func fetchVideoList(keywords: String?) async throws -> [Item]? {
        var key: String = ""
        
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let plistKey = plist["YOUTUBE_KEY"] as? String {
            key = plistKey
            print("✅ Secrets.plist에서 YOUTUBE KEY 로드 성공 (길이: \(plistKey.count))")
        } else {
            key = ""
            print("⚠️ YOUTUBE_KEY를 Secrets.plist에서 찾을 수 없습니다.")
        }
        
        guard let keywords else { return nil }
        let url = "https://www.googleapis.com/youtube/v3/search?part=snippet&relevanceLanguage=ko&type=video&videoEmbeddable=true&videoDuration=medium&key=\(key)&q=\(keywords)"
        
        do {
            let videoModel: VideoModel = try await NetworkManager.shared.request(url: url)
            return videoModel.items
        } catch {
            print("🛑 error: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// JSON 문자열에서 "content" 키의 값을 꺼내 반환
    /// - Parameter jsonString: JSON 전체가 담긴 String
    /// - Returns: "content" 키에 해당하는 문자열, 파싱 실패 시 nil
    private func extractContent(from jsonString: String) -> String? {
        // JSONDecoder로 디코딩할 간단한 모델
        struct Response: Decodable {
            let content: String
        }
        
        // 1) String → Data 변환
        guard let data = jsonString.data(using: .utf8) else {
            print("❌ JSON 문자열을 Data로 변환 실패")
            return nil
        }
        
        // 2) JSON 디코딩 시도
        do {
            let decoded = try JSONDecoder().decode(Response.self, from: data)
            return decoded.content
        } catch {
            print("❌ JSON 파싱 오류:", error.localizedDescription)
            return nil
        }
    }
    
    /// 문자열에서 엔티티(&#39;, &quot;, &amp; 등)를 실제 문자(기호)로 변환하여 반환
    private func htmlDecoded(from str: String) -> String {
        guard let data = str.data(using: .utf8) else { return str }
        
        // NSAttributedString에 HTML 파서 옵션 지정
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        // 파싱 시도
        if let attributed = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return attributed.string
        } else {
            return str
        }
    }
    
    private func prefetchThumbnails(for videos: [VideoRecommendModel]) {
        // 이전 프리패치 취소
        prefetchTasks.forEach { $0.cancel() }
        prefetchTasks.removeAll()

        for v in videos {
            let t = Task {
                _ = await ImageLoader.shared.load(v.thumbnail)
            }
            prefetchTasks.append(t)
        }
    }
}



