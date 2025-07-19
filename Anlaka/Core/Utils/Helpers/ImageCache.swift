//
//  ImageCache.swift
//  Anlaka
//
//  Created by 최정안 on 5/27/25.
//

import UIKit

class ImageCache {
    static let shared = ImageCache()
    private let memoryCache = NSCache<NSString, UIImage>()
    private let maxCacheSize: Int = 50 * 1024 * 1024 // 50MB
    private let queue = DispatchQueue(label: "com.anlaka.imagecache", attributes: .concurrent)
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        memoryCache.totalCostLimit = maxCacheSize
        memoryCache.countLimit = 100 // 최대 100개 이미지
        
        // 캐시 디렉토리 설정
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("ImageCache")
        
        // 캐시 디렉토리 생성
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func setImage(_ image: UIImage, forKey key: String) {
        guard !key.isEmpty else { return }
        
        let scale = image.scale
        let pixelWidth = image.size.width * scale
        let pixelHeight = image.size.height * scale
        let cost = Int(pixelWidth * pixelHeight * 4) // RGBA
        
        // 메모리 캐시에 저장
        queue.async(flags: .barrier) {
            self.memoryCache.setObject(image, forKey: key as NSString, cost: cost)
            print("📸 ImageCache SET: \(key) - Cost: \(cost)")
        }
        
        // 디스크 캐시에 저장
        queue.async {
            self.saveImageToDisk(image, forKey: key)
        }
    }
    
    func image(forKey key: String) -> UIImage? {
        guard !key.isEmpty else { return nil }
        
        return queue.sync {
            // 먼저 메모리 캐시에서 확인
            if let image = memoryCache.object(forKey: key as NSString) {
                print("📸 ImageCache HIT (Memory): \(key)")
                return image
            }
            
            // 메모리 캐시에 없으면 디스크 캐시에서 확인
            if let image = loadImageFromDisk(forKey: key) {
                print("📸 ImageCache HIT (Disk): \(key)")
                // 메모리 캐시에도 저장
                let scale = image.scale
                let pixelWidth = image.size.width * scale
                let pixelHeight = image.size.height * scale
                let cost = Int(pixelWidth * pixelHeight * 4)
                memoryCache.setObject(image, forKey: key as NSString, cost: cost)
                return image
            }
            
            print("📸 ImageCache MISS: \(key)")
            return nil
        }
    }
    
    func removeImage(forKey key: String) {
        guard !key.isEmpty else { return }
        
        queue.async(flags: .barrier) {
            self.memoryCache.removeObject(forKey: key as NSString)
            self.removeImageFromDisk(forKey: key)
        }
    }
    
    func clearCache() {
        queue.async(flags: .barrier) {
            self.memoryCache.removeAllObjects()
            self.clearDiskCache()
        }
    }
    
    // MARK: - Private Methods
    
    private func saveImageToDisk(_ image: UIImage, forKey key: String) {
        let filename = key.replacingOccurrences(of: "/", with: "_")
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: fileURL)
        }
    }
    
    private func loadImageFromDisk(forKey key: String) -> UIImage? {
        let filename = key.replacingOccurrences(of: "/", with: "_")
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        
        return image
    }
    
    private func removeImageFromDisk(forKey key: String) {
        let filename = key.replacingOccurrences(of: "/", with: "_")
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        try? fileManager.removeItem(at: fileURL)
    }
    
    private func clearDiskCache() {
        let contents = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        contents?.forEach { url in
            try? fileManager.removeItem(at: url)
        }
    }
    
    // MARK: - Debug Methods
    
    // 캐시 상태 확인용 메서드
    func getCacheInfo() -> (memoryCount: Int, memoryCost: Int, diskCount: Int) {
        return queue.sync {
            let diskContents = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            return (memoryCache.totalCostLimit, memoryCache.totalCostLimit, diskContents?.count ?? 0)
        }
    }
    
    // 디버깅용: 현재 캐시된 이미지 개수와 총 비용 출력
    func printCacheStatus() {
        queue.sync {
            let diskContents = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            print("📸 ImageCache Status - Memory Count: \(memoryCache.totalCostLimit), Memory Cost: \(memoryCache.totalCostLimit), Disk Count: \(diskContents?.count ?? 0)")
        }
    }
    
    // 디버깅용: 특정 키가 캐시에 있는지 확인
    func contains(key: String) -> Bool {
        return queue.sync {
            if memoryCache.object(forKey: key as NSString) != nil {
                return true
            }
            return loadImageFromDisk(forKey: key) != nil
        }
    }
    
    // 디버깅용: 모든 캐시된 키 출력 (개발용)
    func debugPrintAllKeys() {
        queue.sync {
            let diskContents = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            print("📸 ImageCache Debug - Memory Count: \(memoryCache.totalCostLimit), Disk Count: \(diskContents?.count ?? 0)")
        }
    }
}
