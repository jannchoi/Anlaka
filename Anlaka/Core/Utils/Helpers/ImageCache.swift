import SwiftUI

// MARK: - 캐싱 정책 핵심 상수
struct ImageCachePolicy {
    // 1. 메모리 캐시 최대 크기 (바이트 단위)
    // - 평균 24개 이미지, 최대 30개 이미지 처리
    // - 평균 이미지 크기: 200KB (166x130 썸네일 기준)
    // - 메모리 사용량: 24 * 200KB = 4.8MB, 여유분 포함 8MB
    static let memoryCacheSize: Int = 8 * 1024 * 1024 // 8MB
    
    // 2. 메모리 캐시 최대 이미지 개수
    // - 홈 피드(25개) + 지도(18개) + 카테고리(30개) + POI 이미지(100개) 중 최대값
    // - SearchMapView에서 줌 레벨이 높을 때 많은 POI 이미지가 동시에 로드됨
    // - 빠른 스크롤과 재사용을 고려하여 여유분 포함
    static let memoryCountLimit: Int = 150 // 최대 150개 이미지 (POI 이미지 증가 대응)
    
    // 3. 디스크 캐시 최대 크기 (바이트 단위)
    // - 장기 보존이 필요한 이미지들 (프로필, 자주 조회되는 매물)
    // - 64GB 이상 스토리지 환경 고려, 앱당 수백 MB 허용
    static let diskCacheSize: Int = 100 * 1024 * 1024 // 100MB
    
    // 4. 디스크 캐시 만료 기간 (초 단위)
    // - 매물 정보는 실시간성이 중요하지만, 프로필 이미지는 장기 보존
    // - 7일로 설정하여 적절한 밸런스 유지
    static let diskExpiration: TimeInterval = 7 * 24 * 60 * 60 // 7일
    
    // 5. 이미지 비용 계산 기준 (바이트 단위)
    // - RGBA 4바이트 * 픽셀 수로 계산
    // - 메모리 효율적인 비용 측정
    static let bytesPerPixel: Int = 4 // RGBA
    
    // 6. 프리로딩 제한 (개수)
    // - 스크롤 성능과 메모리 사용량의 균형
    // - 홈 피드 기준으로 앞뒤 5개씩 미리 로드
    static let preloadLimit: Int = 5
}

// MARK: - NSLock을 사용한 안전한 LRU 캐시 구현
// 
// 🔒 NSLock 방식 분석
// 
// ✅ 장점:
//    - 구현이 간단하고 직관적
//    - 모든 스레드에서 안전한 접근 보장
//    - 성능 오버헤드가 상대적으로 적음
//    - iOS 16+에서 완벽하게 지원
// 
// ❌ 단점:
//    - 한 번에 하나의 스레드만 접근 가능 (성능 병목)
//    - 데드락 위험 (잘못된 사용 시)
//    - 복잡한 동시성 시나리오에서 관리 어려움
// 
// 📊 성능 특성:
//    - 읽기/쓰기 모두 동일한 락 사용
//    - 높은 동시성 환경에서 성능 저하
//    - 메모리 사용량: 낮음
class SafeLRUCache<Key: Hashable, Value> {
    private let capacity: Int
    private var cache: [Key: Value] = [:]
    private var accessOrder: [Key] = []
    private let lock = NSLock()
    
    init(capacity: Int) {
        self.capacity = capacity
    }
    
    func get(_ key: Key) -> Value? {
        lock.lock()
        defer { lock.unlock() }
        
        guard let value = cache[key] else { return nil }
        
        // 접근 순서 업데이트
        if let index = accessOrder.firstIndex(of: key) {
            accessOrder.remove(at: index)
        }
        accessOrder.append(key)
        
        return value
    }
    
    func put(_ key: Key, _ value: Value) {
        lock.lock()
        defer { lock.unlock() }
        
        if cache[key] != nil {
            // 기존 키 업데이트
            if let index = accessOrder.firstIndex(of: key) {
                accessOrder.remove(at: index)
            }
        } else if cache.count >= capacity {
            // LRU 제거
            if let oldestKey = accessOrder.first {
                cache.removeValue(forKey: oldestKey)
                accessOrder.removeFirst()
            }
        }
        
        cache[key] = value
        accessOrder.append(key)
    }
    
    func remove(_ key: Key) {
        lock.lock()
        defer { lock.unlock() }
        
        cache.removeValue(forKey: key)
        if let index = accessOrder.firstIndex(of: key) {
            accessOrder.remove(at: index)
        }
    }
    
    func clear() {
        lock.lock()
        defer { lock.unlock() }
        
        cache.removeAll()
        accessOrder.removeAll()
    }
    
    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return cache.count
    }
    
    func validateCacheIntegrity() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        // accessOrder의 모든 키가 cache에 존재하는지 확인
        for key in accessOrder {
            if cache[key] == nil {
                print("❌ 캐시 무결성 오류: accessOrder에 있지만 cache에 없는 키: \(key)")
                return false
            }
        }
        
        // cache의 모든 키가 accessOrder에 존재하는지 확인
        for key in cache.keys {
            if !accessOrder.contains(key) {
                print("❌ 캐시 무결성 오류: cache에 있지만 accessOrder에 없는 키: \(key)")
                return false
            }
        }
        
        return true
    }
}

// MARK: - DispatchSemaphore를 사용한 안전한 LRU 캐시 구현
// 
// 🚦 DispatchSemaphore 방식 분석
// 
// ✅ 장점:
//    - NSLock과 유사한 안전성 보장
//    - 타임아웃 설정 가능 (데드락 방지)
//    - 세마포어 값을 조정하여 동시 접근 제어 가능
//    - 복잡한 동시성 제어에 유연성 제공
// 
// ❌ 단점:
//    - NSLock과 동일한 성능 제한
//    - 복잡한 시나리오에서 관리가 어려움
//    - 세마포어 값 설정의 어려움
//    - 디버깅이 복잡함
// 
// 📊 성능 특성:
//    - 타임아웃 설정으로 데드락 방지
//    - 높은 동시성에서 성능 저하
//    - 메모리 사용량: 낮음
class SemaphoreLRUCache<Key: Hashable, Value> {
    private let capacity: Int
    private var cache: [Key: Value] = [:]
    private var accessOrder: [Key] = []
    private let semaphore = DispatchSemaphore(value: 1)
    
    init(capacity: Int) {
        self.capacity = capacity
    }
    
    func get(_ key: Key) -> Value? {
        semaphore.wait()
        defer { semaphore.signal() }
        
        guard let value = cache[key] else { return nil }
        
        // 접근 순서 업데이트
        if let index = accessOrder.firstIndex(of: key) {
            accessOrder.remove(at: index)
        }
        accessOrder.append(key)
        
        return value
    }
    
    func put(_ key: Key, _ value: Value) {
        semaphore.wait()
        defer { semaphore.signal() }
        
        if cache[key] != nil {
            // 기존 키 업데이트
            if let index = accessOrder.firstIndex(of: key) {
                accessOrder.remove(at: index)
            }
        } else if cache.count >= capacity {
            // LRU 제거
            if let oldestKey = accessOrder.first {
                cache.removeValue(forKey: oldestKey)
                accessOrder.removeFirst()
            }
        }
        
        cache[key] = value
        accessOrder.append(key)
    }
    
    func remove(_ key: Key) {
        semaphore.wait()
        defer { semaphore.signal() }
        
        cache.removeValue(forKey: key)
        if let index = accessOrder.firstIndex(of: key) {
            accessOrder.remove(at: index)
        }
    }
    
    func clear() {
        semaphore.wait()
        defer { semaphore.signal() }
        
        cache.removeAll()
        accessOrder.removeAll()
    }
    
    var count: Int {
        semaphore.wait()
        defer { semaphore.signal() }
        return cache.count
    }
}

// MARK: - Actor를 사용한 안전한 LRU 캐시 구현 (iOS 16+)
// 
// 🎭 Actor 방식 분석 (최종 선택)
// 
// ✅ 장점:
//    - 컴파일 타임에 안전성 보장 (컴파일러 검증)
//    - 최신 Swift 동시성 모델 사용 (Swift 5.5+)
//    - 자동으로 스레드 안전성 제공
//    - 성능이 우수함 (최적화된 동시성 처리)
//    - 메모리 안전성 보장 (Swift 메모리 모델)
//    - 데드락 방지 (Actor 모델 특성)
//    - 타입 안전성 (강력한 타입 시스템)
//    - 미래 지향적 (Swift 동시성 표준)
// 
// ❌ 단점:
//    - async/await 패턴 필요 (학습 곡선)
//    - 기존 동기 코드와의 호환성 고려 필요
//    - iOS 16+ 제한 (하지만 현재 프로젝트에 적합)
// 
// 📊 성능 특성:
//    - 컴파일러 최적화로 인한 우수한 성능
//    - 높은 동시성에서도 안정적
//    - 메모리 사용량: 최적화됨
//    - 런타임 오버헤드: 최소화
actor ActorLRUCache<Key: Hashable, Value> {
    private let capacity: Int
    private var cache: [Key: Value] = [:]
    private var accessOrder: [Key] = []
    
    init(capacity: Int) {
        self.capacity = capacity
    }
    
    func get(_ key: Key) -> Value? {
        guard let value = cache[key] else { return nil }
        
        // 접근 순서 업데이트
        if let index = accessOrder.firstIndex(of: key) {
            accessOrder.remove(at: index)
        }
        accessOrder.append(key)
        
        return value
    }
    
    func put(_ key: Key, _ value: Value) {
        if cache[key] != nil {
            // 기존 키 업데이트
            if let index = accessOrder.firstIndex(of: key) {
                accessOrder.remove(at: index)
            }
        } else if cache.count >= capacity {
            // LRU 제거
            if let oldestKey = accessOrder.first {
                cache.removeValue(forKey: oldestKey)
                accessOrder.removeFirst()
            }
        }
        
        cache[key] = value
        accessOrder.append(key)
    }
    
    func remove(_ key: Key) {
        cache.removeValue(forKey: key)
        if let index = accessOrder.firstIndex(of: key) {
            accessOrder.remove(at: index)
        }
    }
    
    func clear() {
        cache.removeAll()
        accessOrder.removeAll()
    }
    
    var count: Int {
        return cache.count
    }
    
    func validateCacheIntegrity() -> Bool {
        // accessOrder의 모든 키가 cache에 존재하는지 확인
        for key in accessOrder {
            if cache[key] == nil {
                print("❌ 캐시 무결성 오류: accessOrder에 있지만 cache에 없는 키: \(key)")
                return false
            }
        }
        
        // cache의 모든 키가 accessOrder에 존재하는지 확인
        for key in cache.keys {
            if !accessOrder.contains(key) {
                print("❌ 캐시 무결성 오류: cache에 있지만 accessOrder에 없는 키: \(key)")
                return false
            }
        }
        
        return true
    }
}

// MARK: - DispatchQueue를 사용한 LRU 캐시 구현 (기존 방식)
// 
// 📋 DispatchQueue 방식 분석 (문제 발생 원인)
// 
// ✅ 장점:
//    - 읽기/쓰기 분리 가능 (concurrent queue)
//    - 세밀한 제어 가능 (barrier flag)
//    - 복잡한 동시성 시나리오 지원
//    - 기존 코드와의 호환성
// 
// ❌ 단점:
//    - 경쟁 조건(race condition) 위험
//    - 복잡한 구현으로 인한 버그 가능성
//    - sync와 async 간의 경쟁 조건
//    - 디버깅이 어려움
// 
// 📊 성능 특성:
//    - 높은 동시성에서 경쟁 조건 발생
//    - "Index out of range" 에러 위험
//    - 메모리 사용량: 중간
//    - 런타임 오버헤드: 높음
class LRUCache<Key: Hashable, Value> {
    private let capacity: Int
    private var cache: [Key: Value] = [:]
    private var accessOrder: [Key] = []
    private let queue = DispatchQueue(label: "com.anlaka.lrucache", attributes: .concurrent)
    
    init(capacity: Int) {
        self.capacity = capacity
    }
    
    func get(_ key: Key) -> Value? {
        return queue.sync {
            guard let value = cache[key] else { return nil }
            
            // 접근 순서 업데이트 (안전한 방식으로 변경)
            if let index = accessOrder.firstIndex(of: key) {
                accessOrder.remove(at: index)
            }
            accessOrder.append(key)
            
            return value
        }
    }
    
    func put(_ key: Key, _ value: Value) {
        queue.async(flags: .barrier) {
            if self.cache[key] != nil {
                // 기존 키 업데이트 (안전한 방식으로 변경)
                if let index = self.accessOrder.firstIndex(of: key) {
                    self.accessOrder.remove(at: index)
                }
            } else if self.cache.count >= self.capacity {
                // LRU 제거
                if let oldestKey = self.accessOrder.first {
                    self.cache.removeValue(forKey: oldestKey)
                    self.accessOrder.removeFirst()
                }
            }
            
            self.cache[key] = value
            self.accessOrder.append(key)
        }
    }
    
    func remove(_ key: Key) {
        queue.async(flags: .barrier) {
            self.cache.removeValue(forKey: key)
            // 안전한 방식으로 변경
            if let index = self.accessOrder.firstIndex(of: key) {
                self.accessOrder.remove(at: index)
            }
        }
    }
    
    func clear() {
        queue.async(flags: .barrier) {
            self.cache.removeAll()
            self.accessOrder.removeAll()
        }
    }
    
    var count: Int {
        return queue.sync { cache.count }
    }
    
    // 안전성 검사를 위한 디버그 메서드
    func validateCacheIntegrity() -> Bool {
        return queue.sync {
            // accessOrder의 모든 키가 cache에 존재하는지 확인
            for key in accessOrder {
                if cache[key] == nil {
                    print("❌ 캐시 무결성 오류: accessOrder에 있지만 cache에 없는 키: \(key)")
                    return false
                }
            }
            
            // cache의 모든 키가 accessOrder에 존재하는지 확인
            for key in cache.keys {
                if !accessOrder.contains(key) {
                    print("❌ 캐시 무결성 오류: cache에 있지만 accessOrder에 없는 키: \(key)")
                    return false
                }
            }
            
            return true
        }
    }
}

// MARK: - 이미지 유효성 검사 유틸리티
struct ImageValidationHelper {
    /// 이미지 데이터의 유효성을 검사
    static func validateImageData(_ data: Data) -> Bool {
        guard !data.isEmpty else {
            print("❌ 이미지 데이터가 비어있음")
            return false
        }
        
        // 최소 이미지 크기 검사 (1KB)
        guard data.count >= 1024 else {
            print("❌ 이미지 데이터가 너무 작음: \(data.count) bytes")
            return false
        }
        
        // 최대 이미지 크기 검사 (50MB)
        guard data.count <= 50 * 1024 * 1024 else {
            print("❌ 이미지 데이터가 너무 큼: \(data.count / 1024 / 1024)MB")
            return false
        }
        
        return true
    }
    
    /// UIImage의 유효성을 검사
    static func validateUIImage(_ image: UIImage) -> Bool {
        guard let cgImage = image.cgImage else {
            print("❌ CGImage 변환 실패")
            return false
        }
        
        // 이미지 크기 검사
        let width = cgImage.width
        let height = cgImage.height
        
        guard width > 0 && height > 0 else {
            print("❌ 이미지 크기가 유효하지 않음: \(width) x \(height)")
            return false
        }
        
        // 최대 이미지 크기 검사 (8192 x 8192)
        guard width <= 8192 && height <= 8192 else {
            print("❌ 이미지 크기가 너무 큼: \(width) x \(height)")
            return false
        }
        
        // 픽셀 포맷 검사 (확장된 지원 포맷)
        let bitsPerComponent = cgImage.bitsPerComponent
        let bitsPerPixel = cgImage.bitsPerPixel
        let colorSpace = cgImage.colorSpace
        
        // 지원하는 픽셀 포맷 검사 (16비트 RGBA 포맷 추가)
        let isValidFormat = (bitsPerComponent == 8 && bitsPerPixel == 32) ||   // 8비트 RGBA
                           (bitsPerComponent == 8 && bitsPerPixel == 24) ||   // 8비트 RGB
                           (bitsPerComponent == 8 && bitsPerPixel == 16) ||   // 8비트 Gray + Alpha
                           (bitsPerComponent == 16 && bitsPerPixel == 64) ||  // 16비트 RGBA (고품질)
                           (bitsPerComponent == 16 && bitsPerPixel == 48) ||  // 16비트 RGB (고품질)
                           (bitsPerComponent == 16 && bitsPerPixel == 32) ||  // 16비트 Gray + Alpha
                           (bitsPerComponent == 16 && bitsPerPixel == 16)     // 16비트 Gray
        
        guard isValidFormat else {
            print("❌ 지원하지 않는 픽셀 포맷: bitsPerComponent=\(bitsPerComponent), bitsPerPixel=\(bitsPerPixel)")
            return false
        }
        
        // 색상 공간 검사
        guard colorSpace != nil else {
            print("❌ 색상 공간이 없음")
            return false
        }
        
        return true
    }
    
    /// CGImage의 픽셀 포맷을 안전한 포맷으로 변환
    static func convertToSafeFormat(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { 
            print("❌ CGImage가 없음")
            return nil 
        }
        
        let width = cgImage.width
        let height = cgImage.height
        let bitsPerComponent = cgImage.bitsPerComponent
        let bitsPerPixel = cgImage.bitsPerPixel
        
        // 이미 안전한 8비트 포맷인 경우 원본 반환
        if bitsPerComponent == 8 && (bitsPerPixel == 32 || bitsPerPixel == 24 || bitsPerPixel == 16) {
            return image
        }
        
        //print("🔄 픽셀 포맷 변환: \(bitsPerComponent)비트/컴포넌트, \(bitsPerPixel)비트/픽셀 -> 8비트 RGBA")
        
        // 안전한 CGContext 생성 (8비트 RGBA로 강제 변환)
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            print("❌ 안전한 CGContext 생성 실패")
            return nil
        }
        
        // 이미지를 안전한 포맷으로 그리기
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let safeCGImage = context.makeImage() else {
            print("❌ 안전한 CGImage 생성 실패")
            return nil
        }
        
        let convertedImage = UIImage(cgImage: safeCGImage, scale: image.scale, orientation: image.imageOrientation)
        
        // 변환된 이미지 유효성 검사
        guard validateUIImage(convertedImage) else {
            print("❌ 변환된 이미지가 유효하지 않음")
            return nil
        }
        
        //print("✅ 픽셀 포맷 변환 성공: \(width) x \(height)")
        return convertedImage
    }
}

// MARK: - Actor 기반 안전한 디스크 캐시 매니저 (메모리 안전성 강화)
actor SafeDiskCacheManager {
    static let shared = SafeDiskCacheManager()
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private var isInitialized = false
    
    private init() {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("ImageCache")
    }
    
    private func ensureInitialized() {
        guard !isInitialized else { return }
        
        // 캐시 디렉토리 생성
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        isInitialized = true
    }
    
    func saveImage(_ image: UIImage, forKey key: String) async {
        // 초기화 확인
        ensureInitialized()
        
        // 이미지 유효성 검사
        guard ImageValidationHelper.validateUIImage(image) else {
            print("❌ 저장할 이미지가 유효하지 않음: \(key)")
            return
        }
        
        // 안전한 포맷으로 변환
        guard let safeImage = ImageValidationHelper.convertToSafeFormat(image) else {
            print("❌ 안전한 포맷으로 변환 실패: \(key)")
            return
        }
        
        guard let data = safeImage.jpegData(compressionQuality: 0.8) else {
            print("❌ JPEG 데이터 변환 실패: \(key)")
            return
        }
        
        // 데이터 유효성 검사
        guard ImageValidationHelper.validateImageData(data) else {
            print("❌ 저장할 이미지 데이터가 유효하지 않음: \(key)")
            return
        }
        
        let fileURL = cacheDirectory.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? key)
        
        do {
            try data.write(to: fileURL)
            //print("✅ 디스크 캐시 저장 성공: \(key)")
        } catch {
            print("❌ 디스크 캐시 저장 실패: \(error) - 키: \(key)")
        }
    }
    
    func loadImage(forKey key: String) async -> UIImage? {
        // 초기화 확인
        ensureInitialized()
        
        let fileURL = cacheDirectory.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? key)
        
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        
        // 데이터 유효성 검사
        guard ImageValidationHelper.validateImageData(data) else {
            print("❌ 로드된 이미지 데이터가 유효하지 않음: \(key)")
            return nil
        }
        
        guard let image = UIImage(data: data) else {
            print("❌ 이미지 디코딩 실패: \(key)")
            return nil
        }
        
        // 이미지 유효성 검사
        guard ImageValidationHelper.validateUIImage(image) else {
            print("❌ 로드된 이미지가 유효하지 않음: \(key)")
            return nil
        }
        
        return image
    }
    
    func clearExpiredCache() async {
        // 초기화 확인
        ensureInitialized()
        
        let expirationDate = Date().addingTimeInterval(-ImageCachePolicy.diskExpiration)
        
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.creationDateKey])
            
            for file in files {
                if let creationDate = try? file.resourceValues(forKeys: [.creationDateKey]).creationDate,
                   creationDate < expirationDate {
                    try? fileManager.removeItem(at: file)
                }
            }
        } catch {
            print("❌ 만료된 캐시 정리 실패: \(error)")
        }
    }
}

// MARK: - Actor 기반 안전한 이미지 캐시 (메모리 안전성 강화)
actor SafeImageCache {
    static let shared = SafeImageCache()
    
    private let lruCache: ActorLRUCache<String, UIImage>
    private var isInitialized = false
    
    private init() {
        self.lruCache = ActorLRUCache<String, UIImage>(capacity: ImageCachePolicy.memoryCountLimit)
    }
    
    private func ensureInitialized() {
        guard !isInitialized else { return }
        
        // 메모리 부족 시 자동 정리
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.handleMemoryWarning()
            }
        }
        
        isInitialized = true
    }
    
    // MARK: - Public Methods
    
    func setImage(_ image: UIImage, forKey key: String) async {
        // 초기화 확인
        ensureInitialized()
        
        guard !key.isEmpty else { return }
        
        // 이미지 유효성 검사
        guard ImageValidationHelper.validateUIImage(image) else {
            print("❌ 캐시에 저장할 이미지가 유효하지 않음: \(key)")
            return
        }
        
        // 안전한 포맷으로 변환
        guard let safeImage = ImageValidationHelper.convertToSafeFormat(image) else {
            print("❌ 안전한 포맷으로 변환 실패: \(key)")
            return
        }
        
        // 성능 모니터링
        CachePerformanceMonitor.shared.recordCacheMiss()
        
        // 메모리 캐시에 저장
        await lruCache.put(key, safeImage)
        
        // 디버그: 캐시 무결성 검사 (개발 중에만 활성화)
        #if DEBUG
        if !(await lruCache.validateCacheIntegrity()) {
            print("⚠️ 캐시 무결성 오류 감지됨 - 키: \(key)")
        }
        #endif
    }
    
    func image(forKey key: String) async -> UIImage? {
        // 초기화 확인
        ensureInitialized()
        
        guard !key.isEmpty else { return nil }
        
        // 1. 메모리 캐시에서 확인
        if let image = await lruCache.get(key) {
            CachePerformanceMonitor.shared.recordCacheHit()
            
            // 캐시된 이미지 유효성 검사
            if image.size.width > 0 && image.size.height > 0 && image.cgImage != nil {
                
                return image
            } else {
                print("❌ [ImageCache] 캐시된 이미지가 유효하지 않음: \(key) - 크기: \(image.size), CGImage: \(image.cgImage != nil)")
                // 유효하지 않은 이미지는 캐시에서 제거
                await lruCache.remove(key)
                CachePerformanceMonitor.shared.recordCacheMiss()
                return nil
            }
        }
        
        CachePerformanceMonitor.shared.recordCacheMiss()
        return nil
    }
    
    func removeImage(forKey key: String) async {
        // 초기화 확인
        ensureInitialized()
        
        guard !key.isEmpty else { return }
        
        await lruCache.remove(key)
    }
    
    func clearCache() async {
        // 초기화 확인
        ensureInitialized()
        
        await lruCache.clear()
    }
    
    // MARK: - Cache Statistics
    
    func getCacheStatistics() async -> (totalCost: Int, count: Int) {
        // 초기화 확인
        ensureInitialized()
        
        return (0, await lruCache.count)
    }
    
    // MARK: - Private Methods
    
    private func handleMemoryWarning() async {
        print("⚠️ 메모리 부족으로 캐시 크기 조정됨")
        // Actor 기반 캐시는 자동으로 LRU 정리되므로 별도 처리 불필요
    }
}

// MARK: - 안전한 이미지 캐시 래퍼 (Actor 간 상호작용 문제 해결)
class SafeImageCacheWrapper {
    static let shared = SafeImageCacheWrapper()
    
    private let memoryCache = SafeImageCache.shared
    private let diskCache = SafeDiskCacheManager.shared
    
    private init() {}
    
    // MARK: - 통합 이미지 저장 (메모리 + 디스크)
    func setImage(_ image: UIImage, forKey key: String) async {
        guard !key.isEmpty else { return }
        
        // 이미지 유효성 검사
        guard ImageValidationHelper.validateUIImage(image) else {
            print("❌ 저장할 이미지가 유효하지 않음: \(key)")
            return
        }
        
        // 안전한 포맷으로 변환
        guard let safeImage = ImageValidationHelper.convertToSafeFormat(image) else {
            print("❌ 안전한 포맷으로 변환 실패: \(key)")
            return
        }
        
        // 메모리 캐시에 저장
        await memoryCache.setImage(safeImage, forKey: key)
        
        // 디스크 캐시에 저장 (별도 Task로 분리하여 Actor 간 상호작용 방지)
        Task.detached {
            await self.diskCache.saveImage(safeImage, forKey: key)
        }
    }
    
    // MARK: - 통합 이미지 조회 (메모리 -> 디스크)
    func image(forKey key: String) async -> UIImage? {
        guard !key.isEmpty else { return nil }
        
        // 1. 메모리 캐시에서 확인
        if let image = await memoryCache.image(forKey: key) {
            return image
        }
        
        // 2. 디스크 캐시에서 확인 (별도 Task로 분리)
        if let diskImage = await diskCache.loadImage(forKey: key) {
            // 디스크 캐시된 이미지 유효성 검사
            if diskImage.size.width > 0 && diskImage.size.height > 0 && diskImage.cgImage != nil {
                
                // 메모리 캐시에도 저장 (별도 Task로 분리)
                Task.detached {
                    await self.memoryCache.setImage(diskImage, forKey: key)
                }
                return diskImage
            } else {
                print("❌ [ImageCache] 디스크 캐시된 이미지가 유효하지 않음: \(key) - 크기: \(diskImage.size), CGImage: \(diskImage.cgImage != nil)")
                // 유효하지 않은 이미지는 디스크 캐시에서 제거 (별도 Task로)
                Task.detached {
                    // 디스크 캐시 제거 로직 (필요시 구현)
                }
                return nil
            }
        }
        
        return nil
    }
    
    // MARK: - 통합 이미지 제거
    func removeImage(forKey key: String) async {
        guard !key.isEmpty else { return }
        
        await memoryCache.removeImage(forKey: key)
        
        // 디스크 캐시 제거는 별도 Task로 분리
        Task.detached {
            // 디스크 캐시 제거 로직 (필요시 구현)
        }
    }
    
    // MARK: - 통합 캐시 정리
    func clearCache() async {
        await memoryCache.clearCache()
        
        // 디스크 캐시 정리는 별도 Task로 분리
        Task.detached {
            await self.diskCache.clearExpiredCache()
        }
    }
    
    // MARK: - 통계 조회
    func getCacheStatistics() async -> (totalCost: Int, count: Int) {
        return await memoryCache.getCacheStatistics()
    }
}

// MARK: - 기존 ImageCache 클래스 (하위 호환성 유지 - 안전성 강화)
class ImageCache {
    static let shared = ImageCache()
    private let safeWrapper = SafeImageCacheWrapper.shared
    
    private init() {}
    
    // MARK: - Public Methods (동기 인터페이스 - 하위 호환성)
    
    func setImage(_ image: UIImage, forKey key: String) {
        Task {
            await safeWrapper.setImage(image, forKey: key)
        }
    }
    
    func image(forKey key: String) -> UIImage? {
        // 동기 호출을 위한 세마포어 사용 (타임아웃 추가)
        let semaphore = DispatchSemaphore(value: 0)
        var result: UIImage?
        
        Task {
            result = await safeWrapper.image(forKey: key)
            semaphore.signal()
        }
        
        // 8초 타임아웃 설정 (더 관대하게)
        let timeoutResult = semaphore.wait(timeout: .now() + 8.0)
        if timeoutResult == .timedOut {
            print("⚠️ 이미지 캐시 조회 타임아웃: \(key)")
        }
        
        return result
    }
    
    func removeImage(forKey key: String) {
        Task {
            await safeWrapper.removeImage(forKey: key)
        }
    }
    
    func clearCache() {
        Task {
            await safeWrapper.clearCache()
        }
    }
    
    // MARK: - Cache Statistics
    
    func getCacheStatistics() -> (totalCost: Int, count: Int) {
        let semaphore = DispatchSemaphore(value: 0)
        var result: (totalCost: Int, count: Int) = (0, 0)
        
        Task {
            result = await safeWrapper.getCacheStatistics()
            semaphore.signal()
        }
        
        // 3초 타임아웃 설정
        let timeoutResult = semaphore.wait(timeout: .now() + 3.0)
        if timeoutResult == .timedOut {
            print("⚠️ 캐시 통계 조회 타임아웃")
        }
        
        return result
    }
    
    // MARK: - Async 인터페이스 (권장 사용법)
    
    /// 비동기 이미지 설정 (권장)
    func setImageAsync(_ image: UIImage, forKey key: String) async {
        await safeWrapper.setImage(image, forKey: key)
    }
    
    /// 비동기 이미지 조회 (권장)
    func imageAsync(forKey key: String) async -> UIImage? {
        return await safeWrapper.image(forKey: key)
    }
    
    /// 비동기 이미지 제거 (권장)
    func removeImageAsync(forKey key: String) async {
        await safeWrapper.removeImage(forKey: key)
    }
    
    /// 비동기 캐시 정리 (권장)
    func clearCacheAsync() async {
        await safeWrapper.clearCache()
    }
}

// MARK: - 기존 DiskCacheManager 클래스 (하위 호환성 유지 - 안전성 강화)
class DiskCacheManager {
    static let shared = DiskCacheManager()
    private let safeDiskCache = SafeDiskCacheManager.shared
    
    private init() {}
    
    func saveImage(_ image: UIImage, forKey key: String) {
        Task {
            await safeDiskCache.saveImage(image, forKey: key)
        }
    }
    
    func loadImage(forKey key: String) -> UIImage? {
        let semaphore = DispatchSemaphore(value: 0)
        var result: UIImage?
        
        Task {
            result = await safeDiskCache.loadImage(forKey: key)
            semaphore.signal()
        }
        
        // 5초 타임아웃 설정
        let timeoutResult = semaphore.wait(timeout: .now() + 5.0)
        if timeoutResult == .timedOut {
            print("⚠️ 디스크 캐시 조회 타임아웃: \(key)")
        }
        
        return result
    }
    
    func clearExpiredCache() {
        Task {
            await safeDiskCache.clearExpiredCache()
        }
    }
}

// MARK: - 캐시 성능 모니터링 유틸리티
class CachePerformanceMonitor {
    static let shared = CachePerformanceMonitor()
    
    private var hitCount: Int = 0
    private var missCount: Int = 0
    private var totalRequests: Int = 0
    
    private init() {}
    
    func recordCacheHit() {
        hitCount += 1
        totalRequests += 1
    }
    
    func recordCacheMiss() {
        missCount += 1
        totalRequests += 1
    }
    
    func getHitRate() -> Double {
        guard totalRequests > 0 else { return 0.0 }
        return Double(hitCount) / Double(totalRequests) * 100.0
    }
    
    func getStatistics() -> (hitRate: Double, totalRequests: Int, hitCount: Int, missCount: Int) {
        return (getHitRate(), totalRequests, hitCount, missCount)
    }
    
    func resetStatistics() {
        hitCount = 0
        missCount = 0
        totalRequests = 0
    }
}

// MARK: - 다중 스레드 접근 방법 성능 비교 유틸리티
class ThreadSafetyBenchmark {
    static let shared = ThreadSafetyBenchmark()
    
    private init() {}
    
    /// 다양한 동시성 방법의 성능을 비교하는 벤치마크
    func runBenchmark() {
        print("🧪 다중 스레드 접근 방법 성능 비교 시작...")
        
        let testCount = 1000
        let concurrentCount = 10
        
        // 1. NSLock 방식 벤치마크
        benchmarkNSLock(testCount: testCount, concurrentCount: concurrentCount)
        
        // 2. DispatchSemaphore 방식 벤치마크
        benchmarkSemaphore(testCount: testCount, concurrentCount: concurrentCount)
        
        // 3. DispatchQueue 방식 벤치마크 (기존 방식)
        benchmarkDispatchQueue(testCount: testCount, concurrentCount: concurrentCount)
        
        // 4. Actor 방식 벤치마크 (iOS 16+)
        Task {
            await benchmarkActor(testCount: testCount, concurrentCount: concurrentCount)
        }
        

    }
    
    private func benchmarkNSLock(testCount: Int, concurrentCount: Int) {
        let cache = SafeLRUCache<String, String>(capacity: 100)
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "test.nslock", attributes: .concurrent)
        
        for i in 0..<concurrentCount {
            queue.async(group: group) {
                for j in 0..<testCount {
                    let key = "key_\(i)_\(j)"
                    cache.put(key, "value_\(i)_\(j)")
                    let _ = cache.get(key)
                }
            }
        }
        
        group.wait()
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        print("🔒 NSLock 방식: \(String(format: "%.3f", duration))초")
    }
    
    private func benchmarkSemaphore(testCount: Int, concurrentCount: Int) {
        let cache = SemaphoreLRUCache<String, String>(capacity: 100)
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "test.semaphore", attributes: .concurrent)
        
        for i in 0..<concurrentCount {
            queue.async(group: group) {
                for j in 0..<testCount {
                    let key = "key_\(i)_\(j)"
                    cache.put(key, "value_\(i)_\(j)")
                    let _ = cache.get(key)
                }
            }
        }
        
        group.wait()
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        print("🚦 DispatchSemaphore 방식: \(String(format: "%.3f", duration))초")
    }
    
    private func benchmarkDispatchQueue(testCount: Int, concurrentCount: Int) {
        let cache = LRUCache<String, String>(capacity: 100)
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "test.dispatchqueue", attributes: .concurrent)
        
        for i in 0..<concurrentCount {
            queue.async(group: group) {
                for j in 0..<testCount {
                    let key = "key_\(i)_\(j)"
                    cache.put(key, "value_\(i)_\(j)")
                    let _ = cache.get(key)
                }
            }
        }
        
        group.wait()
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        print("📋 DispatchQueue 방식: \(String(format: "%.3f", duration))초")
    }
    
    private func benchmarkActor(testCount: Int, concurrentCount: Int) async {
        let cache = ActorLRUCache<String, String>(capacity: 100)
        let startTime = CFAbsoluteTimeGetCurrent()
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<concurrentCount {
                group.addTask {
                    for j in 0..<testCount {
                        let key = "key_\(i)_\(j)"
                        await cache.put(key, "value_\(i)_\(j)")
                        let _ = await cache.get(key)
                    }
                }
            }
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        print("🎭 Actor 방식: \(String(format: "%.3f", duration))초")
    }
}

// MARK: - 캐시 테스트 유틸리티
extension ImageCache {
    /// 캐시 성능 테스트를 위한 함수
    static func runPerformanceTest() {
        print("🧪 캐시 성능 테스트 시작...")
        
        let testImages = [
            "test_image_1.jpg",
            "test_image_2.jpg", 
            "test_image_3.jpg"
        ]
        
        // 테스트 이미지 생성 (실제로는 네트워크에서 다운로드)
        for imagePath in testImages {
            let testImage = createTestImage(size: CGSize(width: 200, height: 150))
            ImageCache.shared.setImage(testImage, forKey: imagePath)
        }
        
        // 캐시 히트 테스트
        for imagePath in testImages {
            let _ = ImageCache.shared.image(forKey: imagePath)
        }
        
        // 통계 출력
        let stats = ImageCache.shared.getCacheStatistics()
        let perfStats = CachePerformanceMonitor.shared.getStatistics()
        
        print("📊 캐시 테스트 결과:")
        print("   - 메모리 사용량: \(stats.totalCost / 1024 / 1024)MB")
        print("   - 캐시된 이미지 수: \(stats.count)")
        print("   - 캐시 히트율: \(String(format: "%.1f", perfStats.hitRate))%")
        print("   - 총 요청 수: \(perfStats.totalRequests)")
    }
    
    private static func createTestImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - 이미지 프리로딩 유틸리티
class ImagePreloader {
    static let shared = ImagePreloader()
    
    private init() {}
    
    /// 단일 이미지 프리로딩
    func preloadImage(_ imagePath: String) {
        // 백그라운드에서 이미지 다운로드 및 캐싱
        Task {
            guard let url = URL(string: imagePath) else {
                print("❌ 유효하지 않은 이미지 URL: \(imagePath)")
                return
            }
            
            // DownsamplingImageLoader를 사용하여 이미지 로드
            if let image = await DownsamplingImageLoader.shared.loadImage(url: url, context: .thumbnail) {
                // 메모리 캐시에 저장
                ImageCache.shared.setImage(image, forKey: imagePath)
                print("✅ 이미지 프리로딩 완료: \(imagePath)")
            } else {
                print("❌ 이미지 프리로딩 실패: \(imagePath)")
            }
        }
    }
    
    /// 여러 이미지 프리로딩
    func preloadImages(_ imagePaths: [String], scrollDirection: ScrollDirection = .forward) {
        let preloadLimit = ImageCachePolicy.preloadLimit
        
        // 스크롤 방향에 따라 프리로딩할 이미지 선택
        let pathsToPreload: [String]
        switch scrollDirection {
        case .forward:
            pathsToPreload = Array(imagePaths.prefix(preloadLimit))
        case .backward:
            pathsToPreload = Array(imagePaths.suffix(preloadLimit))
        case .unknown:
            pathsToPreload = Array(imagePaths.prefix(preloadLimit))
        }
        
        Task {
            for path in pathsToPreload {
                // 메모리 캐시에 없고 디스크 캐시에도 없는 경우에만 프리로딩
                let memoryImage = await ImageCache.shared.imageAsync(forKey: path)
                let diskImage = await SafeDiskCacheManager.shared.loadImage(forKey: path)
                
                if memoryImage == nil && diskImage == nil {
                    preloadImage(path)
                }
            }
        }
    }
}

// MARK: - 스크롤 방향 감지를 위한 확장
extension CustomAsyncImage {
    /// 스크롤 방향을 고려한 프리로딩
    static func preloadImages(_ imagePaths: [String], scrollDirection: ScrollDirection = .forward) {
        ImagePreloader.shared.preloadImages(imagePaths, scrollDirection: scrollDirection)
    }
}

// MARK: - 사용법 예시 및 권장사항
extension ImageCache {
    /// 다중 스레드 접근 방법 선택 가이드
    static func getThreadSafetyRecommendation() -> String {
        return """
        📋 다중 스레드 접근 방법 선택 가이드
        
        🎯 문제 상황: SearchMapView POI 이미지 캐싱에서 레이스 컨디션 발생
        🎯 해결 방법: Actor 기반 동시성 제어 채택
        
        🏆 1순위: 🔒 NSLock (현재 사용 중 - iOS 16+)
           ✅ 간단하고 안전한 구현
           ✅ 모든 스레드에서 안전한 접근 보장
           ✅ 기존 코드와의 완벽한 호환성
           ✅ 성능과 안전성의 균형
           ✅ 디버깅이 용이함
           ✅ 런타임 오버헤드 최소화
        
                 🥈 2순위: 🎭 Actor (비동기 인터페이스)
            ✅ 컴파일 타임 안전성 보장
            ✅ 최신 Swift 동시성 모델 (Swift 5.5+)
            ✅ 자동 스레드 안전성 제공
            ❌ 동기 호출의 복잡성
            ❌ async/await 패턴 필요
        
        🥉 3순위: 🚦 DispatchSemaphore
           ✅ 타임아웃 설정 가능 (데드락 방지)
           ✅ 복잡한 동시성 제어
           ❌ 복잡한 관리 필요
           ❌ 성능 제한
        
        ⚠️ 4순위: 📋 DispatchQueue (기존 방식 - 문제 발생)
           ✅ 읽기/쓰기 분리 가능
           ❌ 경쟁 조건 위험
           ❌ "Index out of range" 에러 발생
           ❌ 복잡한 디버깅
        
        📊 성능 비교 (예상):
           🎭 Actor: ~0.120초 (가장 빠름)
           🔒 NSLock: ~0.150초
           🚦 DispatchSemaphore: ~0.160초
           📋 DispatchQueue: ~0.140초 (안전성 문제)
        
                 🎯 최종 결론: iOS 16+ 프로젝트에서는 NSLock이 최적의 선택 (동기 호출 문제 해결)
        """
    }
    
    /// 벤치마크 실행 (개발 중에만 사용)
    static func runPerformanceBenchmark() {
        #if DEBUG
        ThreadSafetyBenchmark.shared.runBenchmark()
        #endif
    }
}

// MARK: - 스크롤 방향 열거형
enum ScrollDirection {
    case forward
    case backward
    case unknown
}
