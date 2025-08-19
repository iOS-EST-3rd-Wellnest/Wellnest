//
//  HomeViewModel.swift
//  Wellnest
//
//  Created by JuYong Lee on 8/6/25.
//

import Foundation
import UIKit

final class HomeViewModel: ObservableObject {
    @Published var userInfo: UserEntity?
    @Published var dailySummaryInfo: DailySummaryEntity?

    @Published var goalList = [String]()
    @Published var hashtagList = [String]()
    @Published var quoteOfTheDay: String?
    @Published var weatherResponse: WeatherRecommendModel?
    @Published var videoList = [VideoRecommendModel]()
    
    private let aiRequest = AISerialProxy()
    private let weatherService = WeatherService()
    private let locationManager = LocationManager()
    private var prompt = RecommendPrompt()
    
    // 프리패치 작업 취소를 위해 핸들 보관
    private var prefetchTasks = [Task<Void, Never>]()
    
    // MARK: - 사용자 정보 조회
    func fetchUserInfo() {
        if let result = try? CoreDataService.shared.fetch(UserEntity.self).first {
            userInfo = result
        }
    }
    
    // MARK: - DailySummaryEntity 조회
    @MainActor
    func fetchDailySummary() async {
        if let entity = try? CoreDataService.shared.fetch(DailySummaryEntity.self).first {
            self.dailySummaryInfo = entity

            if let date = entity.date, Calendar.current.isDate(date, inSameDayAs: Date()) {
                self.hashtagList = decodeJSON(from: entity.hashtag ?? "[]") ?? []
                self.goalList = decodeJSON(from: entity.goal ?? "[]") ?? []
                self.quoteOfTheDay = entity.quoteOfTheDay
                self.weatherResponse = decodeJSON(from: entity.weatherSummary ?? "")
                self.videoList = decodeJSON(from: entity.videoRecommendation ?? "[]") ?? []
            } else {
                await updateDailySummary()
            }
        } else {
            await createDailySummary()
        }
    }
    
    private func buildPayload() async -> DailySummaryModel {
        async let hashtagsTask: [String] = fetchHashtag()
        async let goalsTask: [String] = fetchGoals()
        async let quoteTask: String = fetchQuoteOfTheDay()
        async let weatherTask: WeatherRecommendModel? = fetchWeather()
        async let videoTask: [VideoRecommendModel] = fetchVideo()

        let (hashtags, goals, quote, weather, video) = await (hashtagsTask, goalsTask, quoteTask, weatherTask, videoTask)
        
        return DailySummaryModel(
            date: Date(),
            hashtags: hashtags,
            goals: goals,
            quote: quote,
            weather: weather,
            video: video
        )
    }
    
    private func createDailySummary() async {
        let payload = await buildPayload()
        
        let context = CoreDataService.shared.context
        let entity = DailySummaryEntity(context: context)
        entity.id = UUID()
        entity.date = payload.date
        entity.hashtag = jsonString(payload.hashtags)
        entity.goal = jsonString(payload.goals)
        entity.quoteOfTheDay = payload.quote
        entity.weatherSummary = jsonString(payload.weather)
        entity.videoRecommendation = jsonString(payload.video)
        entity.completeRate = 0
        
        try? CoreDataService.shared.saveContext()
        
        await MainActor.run {
            self.dailySummaryInfo = entity
            self.hashtagList = payload.hashtags
            self.goalList = payload.goals
            self.quoteOfTheDay = payload.quote
            self.weatherResponse = payload.weather
            self.videoList = payload.video
        }
    }
    
    private func updateDailySummary() async {
        guard let entity = dailySummaryInfo else { return }
        
        let payload = await buildPayload()
        entity.date = payload.date
        entity.quoteOfTheDay = payload.quote
        entity.goal = jsonString(payload.goals)
        entity.weatherSummary = jsonString(payload.weather)
        try? CoreDataService.shared.saveContext()

        await MainActor.run {
            self.hashtagList = payload.hashtags
            self.goalList = payload.goals
            self.quoteOfTheDay = payload.quote
            self.weatherResponse = payload.weather
            self.videoList = payload.video
        }
    }
    
    // MARK: - 해시태그
    private func fetchHashtag() async -> [String] {
        do {
            guard let userInfo else { return [] }
            let response = try await aiRequest.request(prompt: prompt.hashtagPrompt(entity: userInfo))
            let decodeHashtag = await aiRequest.extractJSONFromResponse(response.content)
            let hashtagModel: RespnseArrayModel? = decodeJSON(from: decodeHashtag ?? "")

            return hashtagModel?.contents ?? []
        } catch {
            print("해시태그 요청 실패:", error.localizedDescription)
            return []
        }
    }
    
    // MARK: - 목표
    private func fetchGoals() async -> [String] {
        do {
            guard let userInfo else { return [] }
            let response = try await aiRequest.request(prompt: prompt.goalPrompt(entity: userInfo))
            let decodeGoal = await aiRequest.extractJSONFromResponse(response.content)
            let goalModel: RespnseArrayModel? = decodeJSON(from: decodeGoal ?? "")
            
            return goalModel?.contents ?? []
        } catch {
            print("목표 요청 실패:", error.localizedDescription)
            return []
        }
    }

    // MARK: - 오늘의 한마디
    private func fetchQuoteOfTheDay() async -> String {
        do {
            guard let userInfo else { return "" }
            let response = try await aiRequest.request(prompt: prompt.quoteOfTheDayPrompt(entity: userInfo))

            return response.content
        } catch {
            print("오늘의 한마디 요청 실패:", error.localizedDescription)
            return ""
        }
    }

    // MARK: - 날씨
    private func fetchWeather() async -> WeatherRecommendModel? {
        do {
            let location = try await locationManager.requestLocation()
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude

            let current = try await weatherService.fetchCurrentWeather(lat: lat, lon: lon)

            guard let userInfo else { return nil }
            let weatherRes = try await aiRequest.request(prompt: prompt.weatherPrompt(entity: userInfo, currentWeather: current))
            let decodeWeather = await aiRequest.extractJSONFromResponse(weatherRes.content)

            let weatherModel: WeatherRecommendModel? = decodeJSON(from: decodeWeather ?? "")
            return weatherModel
        } catch {
            print("LocationManager 권한 오류:", error.localizedDescription)
            return nil
        }
    }
    
    // MARK: - Alan Ai를 활용한 추천 영상 Youtube 검색
     func fetchVideo() async -> [VideoRecommendModel] {
        do {
            guard let userInfo else { return [] }
            let response = try await aiRequest.request(prompt: prompt.videoPrompt(entity: userInfo))
            
            guard let items = try await fetchVideoList(keywords: response.content) else { return [] }
            
            let models = items.map {
                VideoRecommendModel(
                    id: $0.id.videoID,
                    title: htmlDecoded(from: $0.snippet.title),
                    thumbnail: $0.snippet.thumbnails.medium.url
                )
            }
            
            // 썸네일 프리패치
            prefetchThumbnails(for: models)
            
            return models
        } catch {
            print("동영상 불러오기 실패:", error.localizedDescription)
            return []
        }
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
            print("Secrets.plist에서 YOUTUBE KEY 로드 성공 (길이: \(plistKey.count))")
        } else {
            key = ""
            print("YOUTUBE_KEY를 Secrets.plist에서 찾을 수 없습니다.")
        }
        
        guard let keywords else { return nil }
        let url = "https://www.googleapis.com/youtube/v3/search?part=snippet&relevanceLanguage=ko&type=video&videoEmbeddable=true&videoDuration=medium&key=\(key)&q=\(keywords)"
        
        do {
            let videoModel: VideoModel = try await NetworkManager.shared.request(url: url)
            return videoModel.items
        } catch {
            print("error: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// JSON 문자열에서 원하는 타입으로 decode
    /// - Parameter jsonString: JSON 전체가 담긴 String
    /// - Returns: decode하는 타임으로 반환
    private func decodeJSON<T: Decodable>(from jsonString: String) -> T? {
        
        // 1) String → Data 변환
        guard let data = jsonString.data(using: .utf8) else {
            print("JSON 문자열을 Data로 변환 실패")
            return nil
        }
        
        // 2) JSON 디코딩 시도
        do {
            let decoded = try JSONDecoder().decode(T.self, from: data)
            return decoded
        } catch {
            print("JSON 파싱 오류:", error.localizedDescription)
            return nil
        }
    }
    
    private func jsonString<T: Encodable>(_ value: T?) -> String? {
        guard let value else { return nil }
        do {
            let enc = JSONEncoder()
            enc.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
            let data = try enc.encode(value)
            return String(data: data, encoding: .utf8)
        } catch {
            print("JSON Encoding 실패:", error)
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

actor AISerialProxy {
    private let alanAiService = AlanAIService()

    func request(prompt: String) async throws -> Response {
        try await alanAiService.request(prompt: prompt, responseType: Response.self)
    }
    
    func extractJSONFromResponse(_ response: String) -> String? {
        alanAiService.extractJSONFromResponse(response)
    }
}
