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
    
    private let aiRequest = AISerialProxy()
    private var prompt = RecommendPrompt()
    
    // 프리패치 작업 취소를 위해 핸들 보관
    private var prefetchTasks = [Task<Void, Never>]()
    
    /// 사용자 정보 조회
    func fetchUserInfo() {
        if let result = try? CoreDataService.shared.fetch(UserEntity.self).first {
            userInfo = result
        }
    }
    
    // MARK: - DailySummaryEntity 조회/생성/수정
    /// DailySummaryEntity를 조회하여 Alan을 활용한 컨텐츠 데이터 세팅
    @MainActor
    func fetchDailySummary() async {
        // entity 조회
        if let entity = try? CoreDataService.shared.fetch(DailySummaryEntity.self).first {
            self.dailySummaryInfo = entity
			
            // entity의 날짜가 오늘 이라면
            if let date = entity.date, Calendar.current.isDate(date, inSameDayAs: Date()) {
                // 1) 존재하는 데이터 화면 바인딩
                applyEntityToPublished(entity)
                
                // 2) 누락된 항목 채우기
                await missingFieldsIfNeeded(for: entity)
            } else {
                // entity date가 오늘이 아니라면 컨텐츠 데이터 생성하여 entity 업데이트
                await updateDailySummary()
            }
        } else {
            await createDailySummary()
        }
    }

    
    /// 처음 앱 실행 시 날씨 정보 등록
    func refreshWeatherContent() async {
        guard !Self.isRefreshWeather else { return }
        
        do {
            // 1) 앱 시작 시 프리로드된 예보를 사용
            let forecast = await WeatherCenter.shared.waitForForecast()
            guard let current = forecast.first, let userInfo else { return }
            
            // 2) 날씨 기반 컨텐츠 생성
            let res = try await aiRequest.request(prompt: prompt.weatherPrompt(entity: userInfo, currentWeather: current))
            guard let json = await aiRequest.extractJSONFromResponse(res.content),
                  let model: WeatherRecommendModel = decodeJSON(from: json) else { return }

            // 3) 오늘자 엔티티 업데이트(없으면 생성)
            if let entity = try? CoreDataService.shared.fetch(DailySummaryEntity.self).first {
                // 필드만 갱신 (화면 바인딩 포함)
                print("refreshWeatherContent entity:", entity)
                await updateWeather(model, on: entity)
            } else {
                // 엔티티가 없으면 새로 생성
                let context = CoreDataService.shared.context
                let entity = DailySummaryEntity(context: context)
                entity.id = UUID()
                entity.date = Date()
                entity.weatherSummary = jsonString(model)
                entity.completeRate = 0
                try? CoreDataService.shared.saveContext()

                await MainActor.run {
                    self.dailySummaryInfo = entity
                    self.weatherResponse = model
                }
            }
            
            Self.isRefreshWeather = true
        } catch {
            print("refreshWeatherContenty 실패:", error.localizedDescription)
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
    
    
    /// 신규 생성/업데이트 공통 쓰기
    /// - Parameters:
    ///   - payload: 저장 내용
    ///   - entity: 신규/업데이트 entity 정보
    private func upsert(_ payload: DailySummaryModel, to entity: DailySummaryEntity) {
        entity.date = payload.date
        entity.hashtag = jsonString(payload.hashtags)
        entity.goal = jsonString(payload.goals)
        entity.quoteOfTheDay = payload.quote
        entity.weatherSummary = jsonString(payload.weather)
        entity.videoRecommendation = jsonString(payload.video)
        try? CoreDataService.shared.saveContext()
    }
    
    
    /// 신규 생성
    private func createDailySummary() async {
        let payload = await buildPayload()
        
        let context = CoreDataService.shared.context
        let entity = DailySummaryEntity(context: context)
        entity.id = UUID()
        upsert(payload, to: entity)
        
        await MainActor.run {
            self.dailySummaryInfo = entity
            self.hashtagList = payload.hashtags
            self.goalList = payload.goals
            self.quoteOfTheDay = payload.quote
            self.weatherResponse = payload.weather
            self.videoList = payload.video
        }
    }
    
    
    /// 업데이트
    private func updateDailySummary() async {
        guard let entity = dailySummaryInfo else { return }
        
        let payload = await buildPayload()
        upsert(payload, to: entity)

        await MainActor.run {
            self.hashtagList = payload.hashtags
            self.goalList = payload.goals
            self.quoteOfTheDay = payload.quote
            self.weatherResponse = payload.weather
            self.videoList = payload.video
        }
    }
    
    /// 오늘 엔티티 존재하지만 일부 비어있는(없거나 "[]"/"{}"/공백) 필드 개별 생성해서 저장
    /// - Parameter entity: 오늘 날짜의 entity
    private func missingFieldsIfNeeded(for entity: DailySummaryEntity) async {
        await withTaskGroup(of: Void.self) { group in
            if isMissingJSON(entity.hashtag) {
                group.addTask { [weak self] in
                    guard let self else { return }
                    let hashtags = await self.fetchHashtag()
                    await self.updateHashtags(hashtags, on: entity)
                }
            }
            
            if isMissingJSON(entity.goal) {
                group.addTask { [weak self] in
                    guard let self else { return }
                    let goals = await self.fetchGoals()
                    await self.updateGoals(goals, on: entity)
                }
            }
            
            if (entity.quoteOfTheDay ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                group.addTask { [weak self] in
                    guard let self else { return }
                    let quote = await self.fetchQuoteOfTheDay()
                    await self.updateQuote(quote, on: entity)
                }
            }
            
            if isMissingJSON(entity.weatherSummary) {
                group.addTask { [weak self] in
                    guard let self else { return }
                    let weather = await self.fetchWeather()
                    await self.updateWeather(weather, on: entity)
                }
            }
            
            if isMissingJSON(entity.videoRecommendation) {
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
    
    // MARK: - Alan 연동
    
    /// 사용자 해시태그 생성
    /// - Returns: 해시태그 목록
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
    
    
    /// 하루동안 달성 가능한 목표 추천
    /// - Returns: 목표 목록
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

    
    /// 동기부여되는 문장, 명언 등의 오늘의 한마디
    /// - Returns: 오늘의 한마디 문자열
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

    
    /// 현재 날씨 정보를 바당으로 일정 컨텐츠 추천
    /// - Returns: 날씨 안내 및 추천 일정
    private func fetchWeather() async -> WeatherRecommendModel? {
        do {
            let forecast = await WeatherCenter.shared.waitForForecast()
            
            guard let userInfo, let current = forecast.first  else { return nil }
            let weatherRes = try await aiRequest.request(prompt: prompt.weatherPrompt(entity: userInfo, currentWeather: current))
            let decodeWeather = await aiRequest.extractJSONFromResponse(weatherRes.content)

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
actor AISerialProxy {
    private let alanAiService = AlanAIService()

    func request(prompt: String) async throws -> Response {
        try await alanAiService.request(prompt: prompt, responseType: Response.self)
    }
    
    func extractJSONFromResponse(_ response: String) -> String? {
        alanAiService.extractJSONFromResponse(response)
    }
}
