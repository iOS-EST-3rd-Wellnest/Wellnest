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
    @Published var videoList: [VideoRecommendModel] = []
    @Published var images = [String: UIImage]()
    
    private static let imageCache = NSCache<NSString, UIImage>()
    
    let alanService = AlanAIService()
    
    var prompt = HomePrompt()
    
    
    // MARK: - 오늘의 한마디
    func quoteOfTheDayRequest() {
        
    }
    
    // MARK: - 날씨 Recommend
    func weatherRequest() {
        
    }
    
    
    // MARK: - Alan Ai를 활용한 추천 영상 Youtube 검색
    func videoRequest() {
        Task {
            do {
                let response = try await alanService.requestString(prompt: prompt.promptStr())
                let keywords = extractContent(from: response)
//                let keywords = "체중 감량과 증가를 위한 걷기 운동 및 요가 루틴"
                //print(keywords)
                
                if let items = try await fetchVideoList(keywords: keywords) {
                    let models = items.map { item in
                        VideoRecommendModel(
                            id: item.id.videoID,
                            title: htmlDecoded(from: item.snippet.title),
                            thumbnail: item.snippet.thumbnails.medium.url
                        )
                    }
                    self.videoList = models
                    
                    // 각 비디오의 썸네일 미리 로드
                    for video in models {
                        await loadImage(for: video)
                    }
                }
            } catch {
                print("❌ 동영상 불러오기 실패:", error)
            }
        }
    }
    
    /// 비디오의 썸네일을 비동기 로드해서 images[id]에 저장
    func loadImage(for video: VideoRecommendModel) async {
        guard let url = URL(string: video.thumbnail) else { return }
        let key = video.id as NSString
        
        // 캐시에 이미 있으면 곧장 사용
        if let cached = Self.imageCache.object(forKey: key) {
            images[video.id] = cached
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) {
                Self.imageCache.setObject(uiImage, forKey: key)
                images[video.id] = uiImage
            }
        } catch {
            print("⚠️ 썸네일 로드 실패 (\(video.id)):", error)
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
            print("❌ JSON 파싱 오류:", error)
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
    
}



