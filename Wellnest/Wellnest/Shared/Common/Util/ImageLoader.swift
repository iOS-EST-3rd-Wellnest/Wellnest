//
//  ImageLoader.swift
//  Wellnest
//
//  Created by JuYong Lee on 8/13/25.
//

import Foundation
import UIKit

final class ImageLoader {
    static let shared = ImageLoader()

    private let cache = NSCache<NSString, UIImage>()
    private var memoryWarningObserver: NSObjectProtocol?

    private init() {
        // 메모리 경고 시 캐시 비우기
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.cache.removeAllObjects()
        }
    }
    
    deinit {
        if let token = memoryWarningObserver {
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
            let (data, response) = try await URLSession.shared.data(from: url)
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
            if (error as? URLError)?.code == .cancelled {
                return nil   // 취소 무시
            }
            print("⚠️ Image load failed (\(url)): \(error)")
        }
        return nil
    }
}
