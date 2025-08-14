//
//  ImageLoader.swift
//  Wellnest
//
//  Created by JuYong Lee on 8/13/25.
//

import Foundation
import SwiftUI

protocol ImageLoading {
    func load(_ urlString: String) async -> UIImage?
    func load(_ url: URL) async -> UIImage?
    func removeCache(for urlString: String)
}

final class ImageLoader: ImageLoading {
    static let shared = ImageLoader()

    private let cache = NSCache<NSString, UIImage>()
    private let session: URLSession
    
    private var memoryWarningObserver: NSObjectProtocol?
    private var didEnterBackgroundObserver: NSObjectProtocol?

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.waitsForConnectivity = true
        session = URLSession(configuration: config)
        
        // 메모리 경고 시 캐시 비우기
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.cache.removeAllObjects()
        }
        
        // 앱이 백그라운드로 갈 때 캐시 비우기
        didEnterBackgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.cache.removeAllObjects()
        }
    }
    
    deinit {
        if let token = memoryWarningObserver {
            NotificationCenter.default.removeObserver(token)
        }
        
        if let token = didEnterBackgroundObserver {
            NotificationCenter.default.removeObserver(token)
        }
    }

    // String URL
    func load(_ urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        return await load(url)
    }

    // URL
    func load(_ url: URL) async -> UIImage? {
        let key = url.absoluteString as NSString

        if let cached = cache.object(forKey: key) {
            return cached
        }

        do {
            let (data, response) = try await session.data(from: url)
            if let http = response as? HTTPURLResponse,
               !(200...299).contains(http.statusCode) {
                return nil
            }
            if let img = UIImage(data: data) {
                // 이미지 크기를 비용으로 설정(대략)
                cache.setObject(img, forKey: key, cost: data.count)
                return img
            }
        } catch {
            print("⚠️ Image load failed (\(url)): \(error)")
        }
        return nil
    }

    func removeCache(for urlString: String) {
        cache.removeObject(forKey: urlString as NSString)
    }
}
