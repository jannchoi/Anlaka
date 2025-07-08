
// MARK: - 안전한 캐싱 로직

//
//  ImageCache.swift
//  Anlaka
//
//  Created by 최정안 on 5/27/25.
//

import UIKit

class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    private let maxCacheSize: Int = 50 * 1024 * 1024 // 50MB
    private let queue = DispatchQueue(label: "com.anlaka.imagecache", attributes: .concurrent)
    
    private init() {
        cache.totalCostLimit = maxCacheSize
        cache.countLimit = 200 // 적절한 개수 제한
    }
    
    func setImage(_ image: UIImage, forKey key: String) {
        guard !key.isEmpty else { return }
        
        let scale = image.scale
        let pixelWidth = image.size.width * scale
        let pixelHeight = image.size.height * scale
        let cost = Int(pixelWidth * pixelHeight * 4) // RGBA
        
        // 스레드 안전하게 캐시에 저장
        queue.async(flags: .barrier) {
            self.cache.setObject(image, forKey: key as NSString, cost: cost)
        }
    }
    
    func image(forKey key: String) -> UIImage? {
        guard !key.isEmpty else { return nil }
        
        // 스레드 안전하게 캐시에서 검색
        return queue.sync {
            return cache.object(forKey: key as NSString)
        }
    }
    
    func removeImage(forKey key: String) {
        guard !key.isEmpty else { return }
        
        queue.async(flags: .barrier) {
            self.cache.removeObject(forKey: key as NSString)
        }
    }
    
    func clearCache() {
        queue.async(flags: .barrier) {
            self.cache.removeAllObjects()
        }
    }
}
