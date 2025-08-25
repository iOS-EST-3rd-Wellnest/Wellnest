//
//  HomeViewModel.swift
//  Wellnest
//
//  Created by JuYong Lee on 8/6/25.
//

import Foundation
import SwiftUI

final class HomeViewModel: ObservableObject {
    @Published var userInfo: UserEntity?
    @Published var dailySummaryInfo: DailySummaryEntity?

    @Published var goalList = [String]()
    @Published var hashtagList = [String]()
    @Published var quoteOfTheDay: String?
    @Published var weatherResponse: WeatherRecommendModel?
    @Published var videoList = [VideoRecommendModel]()
    
    private static var isRefreshWeather = false
    
    private let aiRequest = AIServiceProxy()
    private var prompt = RecommendPrompt()
    
    // 프리패치 작업 취소를 위해 핸들 보관
    private var prefetchTasks = [Task<Void, Never>]()
    
    // MARK: - DailySummaryEntity 조회/생성/수정
    /// DailySummaryEntity를 조회하여 Alan을 활용한 컨텐츠 데이터 세팅
    @MainActor
    func fetchDailySummary() async {
        // 사용자 정보 조회
        if let result = try? CoreDataService.shared.fetch(UserEntity.self).first {
            self.userInfo = result
        }
        
        // 오늘 엔티티 확보(없으면 생성, 있으면 재사용)
        let entity = ensureTodayEntity()
        self.dailySummaryInfo = entity
        
        // 화면에 기존 값 바인딩
        applyEntityToPublished(entity)
        
        // 오늘이면 누락만 채우고, 어제(이전) 데이터면 전체 갱신
        var isOnlyMissing = true
        if let date = entity.date, !Calendar.current.isDate(date, inSameDayAs: Date()) {
            entity.date = Date()
            try? CoreDataService.shared.saveContext()
            isOnlyMissing = false
        }
        
        // 필드별 병렬 요청 → 끝나는 즉시 저장 & 반영
        await populateFieldsConcurrently(on: entity, isOnlyMissing: isOnlyMissing)
    }
    
    /// 처음 앱 실행 시 날씨 정보 등록
    func refreshWeatherContent() async {
        guard !Self.isRefreshWeather else { return }
        
        do {
            // 1) 앱 시작 시 프리로드된 예보를 사용
            let forecast = await WeatherCenter.shared.waitForForecast()
            guard let current = forecast.first, let userInfo else { return }
            
            // 2) 날씨 기반 컨텐츠 생성 (요청당 프록시 생성)
            let aiService = AIServiceProxy()
            let res = try await aiService.request(prompt: prompt.weatherPrompt(entity: userInfo, currentWeather: current))
            guard let json = await aiService.extractJSONFromResponse(res.content),
                  let model: WeatherRecommendModel = decodeJSON(from: json) else { return }
            
            // 3) 오늘자 엔티티 업데이트(없으면 생성)
            let entity = ensureTodayEntity()
            await updateWeather(model, on: entity)
            
            Self.isRefreshWeather = true
        } catch {
            print("refreshWeatherContenty 실패:", error.localizedDescription)
        }
    }
    
    
    /// entity 데이터  조회 및 생성
    /// 기존 entity 데이터 조회 후 없으면 생성
    /// - Returns: 조회 또는 신규 생성 DailySummaryEntity
    private func ensureTodayEntity() -> DailySummaryEntity {
        if let entity = try? CoreDataService.shared.fetch(DailySummaryEntity.self).first {
            return entity
        } else {
            let context = CoreDataService.shared.context
            let entity = DailySummaryEntity(context: context)
            entity.id = UUID()
            entity.date = Date()
            try? CoreDataService.shared.saveContext()
            return entity
        }
    }
    
    
    /// 컨텐츠 개별 fetch 및 저장
    /// - Parameters:
    ///   - entity: 기존 또느 생성된 entity
    ///   - isOnlyMissing: 어떤 작업을 처리할지 여부, false: 모든 작업, true: 누락된 것만 추가 작업
    private func populateFieldsConcurrently(on entity: DailySummaryEntity, isOnlyMissing: Bool) async {
        await withTaskGroup(of: Void.self) { group in
            if !isOnlyMissing || isMissingJSON(entity.hashtag) {
                group.addTask { [weak self] in
                    guard let self else { return }
                    let hashtags = await self.fetchHashtag()
                    await self.updateHashtags(hashtags, on: entity)
                }
            }
            
            if !isOnlyMissing || isMissingJSON(entity.goal) {
                group.addTask { [weak self] in
                    guard let self else { return }
                    let goals = await self.fetchGoals()
                    await self.updateGoals(goals, on: entity)
                }
            }
            
            if !isOnlyMissing || (entity.quoteOfTheDay ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                group.addTask { [weak self] in
                    guard let self else { return }
                    let quote = await self.fetchQuoteOfTheDay()
                    await self.updateQuote(quote, on: entity)
                }
            }
            
            if !isOnlyMissing || isMissingJSON(entity.weatherSummary) {
                group.addTask { [weak self] in
                    guard let self else { return }
                    let weather = await self.fetchWeather()
                    await self.updateWeather(weather, on: entity)
                }
            }
            
            if !isOnlyMissing || isMissingJSON(entity.videoRecommendation) {
                group.addTask { [weak self] in
                    guard let self else { return }
                    let videos = await self.fetchVideo()
                    await self.updateVideos(videos, on: entity)
                }
            }
        }
    }
    
    // MARK: - 필드별 업데이트 (개별 저장 및 화면 반영)
    @MainActor
    private func updateHashtags(_ hashtags: [String], on entity: DailySummaryEntity) {
        entity.hashtag = jsonString(hashtags)
        self.hashtagList = hashtags
        try? CoreDataService.shared.saveContext()
    }

    @MainActor
    private func updateGoals(_ goals: [String], on entity: DailySummaryEntity) {
        entity.goal = jsonString(goals)
        self.goalList = goals
        try? CoreDataService.shared.saveContext()
    }

    @MainActor
    private func updateQuote(_ quote: String, on entity: DailySummaryEntity) {
        entity.quoteOfTheDay = quote
        self.quoteOfTheDay = quote
        try? CoreDataService.shared.saveContext()
    }

    @MainActor
    private func updateWeather(_ weather: WeatherRecommendModel?, on entity: DailySummaryEntity) {
        entity.weatherSummary = jsonString(weather)
        self.weatherResponse = weather
        try? CoreDataService.shared.saveContext()
    }

    @MainActor
    private func updateVideos(_ videos: [VideoRecommendModel], on entity: DailySummaryEntity) {
        entity.videoRecommendation = jsonString(videos)
        self.videoList = videos
        try? CoreDataService.shared.saveContext()
    }
    
    private func isMissingJSON(_ json: String?) -> Bool {
        guard let json, !json.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return true
        }
        
        let compact = json.replacingOccurrences(of: "\\s", with: "", options: .regularExpression)
        if compact == "[]" || compact == "{}" { return true }
        return false
    }

    @MainActor
    private func applyEntityToPublished(_ entity: DailySummaryEntity) {
        self.hashtagList = decodeJSON(from: entity.hashtag ?? "[]") ?? []
        self.goalList = decodeJSON(from: entity.goal ?? "[]") ?? []
        self.quoteOfTheDay = entity.quoteOfTheDay
        self.weatherResponse = decodeJSON(from: entity.weatherSummary ?? "")
        self.videoList = decodeJSON(from: entity.videoRecommendation ?? "[]") ?? []
    }
    
    // MARK: - Alan AI 연동
    /// 사용자 해시태그 생성
    /// - Returns: 해시태그 목록
    private func fetchHashtag() async -> [String] {
        do {
            guard let userInfo else { return [] }
            let hashtagAISevice = AIServiceProxy()
            let hashtagResponse = try await hashtagAISevice.request(prompt: prompt.hashtagPrompt(entity: userInfo))
            let decodeHashtag = await hashtagAISevice.extractJSONFromResponse(hashtagResponse.content)
            let hashtagModel: RespnseArrayModel? = decodeJSON(from: decodeHashtag ?? "")

            return hashtagModel?.contents ?? []
        } catch {
            print("해시태그 요청 실패:", error.localizedDescription)
            return []
        }
    }
    
    /// 하루동안 달성 가능한 목표 추천
    /// - Returns: 목표 목록
    private func fetchGoals() async -> [String] {
        do {
            guard let userInfo else { return [] }
            let goalAISevice = AIServiceProxy()
            let goalResponse = try await goalAISevice.request(prompt: prompt.goalPrompt(entity: userInfo))
            let decodeGoal = await goalAISevice.extractJSONFromResponse(goalResponse.content)
            let goalModel: RespnseArrayModel? = decodeJSON(from: decodeGoal ?? "")
            
            return goalModel?.contents ?? []
        } catch {
            print("목표 요청 실패:", error.localizedDescription)
            return []
        }
    }
    
    /// 동기부여되는 문장, 명언 등의 오늘의 한마디
    /// - Returns: 오늘의 한마디 문자열
    private func fetchQuoteOfTheDay() async -> String {
        do {
            guard let userInfo else { return "" }
            let quoteOfTheDayAISevice = AIServiceProxy()
            let quoteOfTheDayResponse = try await quoteOfTheDayAISevice.request(prompt: prompt.quoteOfTheDayPrompt(entity: userInfo))

            return quoteOfTheDayResponse.content
        } catch {
            print("오늘의 한마디 요청 실패:", error.localizedDescription)
            return ""
        }
    }
    
    /// 현재 날씨 정보를 바당으로 일정 컨텐츠 추천
    /// - Returns: 날씨 안내 및 추천 일정
    private func fetchWeather() async -> WeatherRecommendModel? {
        do {
            let forecast = await WeatherCenter.shared.waitForForecast()
            
            guard let userInfo, let current = forecast.first  else { return nil }
            
            let weatherAISevice = AIServiceProxy()
            let weatherResponse = try await weatherAISevice.request(prompt: prompt.weatherPrompt(entity: userInfo, currentWeather: current))
            let decodeWeather = await weatherAISevice.extractJSONFromResponse(weatherResponse.content)
            let weatherModel: WeatherRecommendModel? = decodeJSON(from: decodeWeather ?? "")
            
            return weatherModel
        } catch {
            print("weather 요청 실패:", error.localizedDescription)
            return nil
        }
    }
    
    /// Alan AI에 검색어를 받아 추천 영상 검색
    /// - Returns: 영상 목록
    private func fetchVideo() async -> [VideoRecommendModel] {
        do {
            guard let userInfo else { return [] }
            
            let aiSevice = AIServiceProxy()
            let videoResponse = try await aiSevice.request(prompt: prompt.videoPrompt(entity: userInfo))

            guard let items = try await fetchVideoList(keywords: videoResponse.content) else { return [] }
            
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
    
    /// 다양한 타입의 JSON String 형태로 변환
    /// - Parameter value: 변환하려는 값
    /// - Returns: JSON 형태의 문자열
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
    /// - Parameter str: 문자열
    /// - Returns: 변환된 문자열
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

// MARK: - AlanAIService
actor AIServiceProxy {
    private let alanAiService = AlanAIService()

    func request(prompt: String) async throws -> Response {
        try await alanAiService.request(prompt: prompt, responseType: Response.self)
    }
    
    func extractJSONFromResponse(_ response: String) -> String? {
        alanAiService.extractJSONFromResponse(response)
    }
}
