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
    
    private init() {
        cache.totalCostLimit = maxCacheSize
        // cache.countLimit = 100 // 너무 작을 수 있음, 필요 없다면 제거
    }
    
    func setImage(_ image: UIImage, forKey key: String) {
        guard !key.isEmpty else { return }
        
        let scale = image.scale
        let pixelWidth = image.size.width * scale
        let pixelHeight = image.size.height * scale
        let cost = Int(pixelWidth * pixelHeight * 4) // RGBA
        
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }
    
    func image(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func removeImage(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
}
