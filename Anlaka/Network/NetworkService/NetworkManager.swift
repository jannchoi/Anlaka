//
//  NetworkManager.swift
//  Anlaka
//
//  Created by 최정안 on 5/12/25.
//

import Foundation
import UIKit


// MARK: - 대기 요청을 위한 타입 정보를 포함한 구조체
struct PendingRequest {
    let request: NetworkRequestConvertible
    let completion: (Result<Any, Error>) -> Void
    let modelType: Decodable.Type
    
    init<T: Decodable>(request: NetworkRequestConvertible, model: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        self.request = request
        self.modelType = model
        self.completion = { result in
            switch result {
            case .success(let data):
                if let typedData = data as? T {
                    completion(.success(typedData))
                } else {
                    completion(.failure(CustomError.unknown(code: 500, message: "타입 변환 실패")))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

// MARK: - 토큰 갱신 상태 관리
@MainActor
final class TokenRefreshManager {
    static let shared = TokenRefreshManager()
    
    // 토큰 갱신 진행 상태 플래그
    private var isRefreshingToken: Bool = false
    
    // AccessToken 만료 트리거 플래그
    private var isTokenExpired: Bool = false
    
    // 대기 중인 요청 큐 (최대 10개로 제한)
    private var pendingRequests: [PendingRequest] = []
    private let maxPendingRequests = 10
    
    // 마지막 갱신 시점 (빠른 연속 갱신 방지)
    private var lastRefreshTime: TimeInterval = 0
    private let refreshCooldown: TimeInterval = 0.5 // 0.5초 쿨다운
    
    private init() {}
    
    // MARK: - 토큰 갱신 관리
    
    /// 토큰 만료 트리거 설정
    func setTokenExpired(_ expired: Bool) {
        isTokenExpired = expired
    }
    
    /// 토큰 갱신 시작
    func startTokenRefresh() async throws {
        guard !isRefreshingToken else {
            print("이미 토큰 갱신이 진행 중입니다 - 대기 중...")
            return
        }
        
        let now = Date().timeIntervalSince1970
        isRefreshingToken = true
        lastRefreshTime = now

        
        do {
            // refreshToken 유효성 확인
            let refreshExp = UserDefaultsManager.shared.getInt(forKey: .expRefresh)
            if Int(now) >= refreshExp {
                throw CustomError.expiredRefreshToken
            }
            
            // 토큰 갱신 요청
            let refreshRequest = AuthRouter.getRefreshToken
            let response = try await NetworkManager.shared.executeRequest(refreshRequest, model: RefreshTokenResponseDTO.self)
            
            // 새 토큰 저장
            UserDefaultsManager.shared.set(response.accessToken, forKey: .accessToken)
            UserDefaultsManager.shared.set(response.refreshToken, forKey: .refreshToken)
            
            // 갱신 완료 및 트리거 해제
            completeTokenRefresh()
            print(" 토큰 갱신 성공")
        } catch {
            failTokenRefresh(error: error)
            if error as? CustomError == .expiredRefreshToken {
                await NetworkManager.shared.handleRefreshTokenExpiration()
            }
            throw error
        }
    }
    
    /// 토큰 갱신 완료 (Lock 해제 및 트리거 해제)
    private func completeTokenRefresh() {
        isRefreshingToken = false
        isTokenExpired = false
        executePendingRequests()
        print("토큰 갱신 완료, 만료 트리거 해제")
    }
    
    /// 토큰 갱신 실패 (Lock 해제 및 대기 요청 처리)
    private func failTokenRefresh(error: Error) {
        isRefreshingToken = false
        isTokenExpired = false
        print(" 토큰 갱신 실패: \(error)")
        
        let requests = pendingRequests
        pendingRequests.removeAll()
        
        for pendingRequest in requests {
            pendingRequest.completion(.failure(error))
        }
    }
    
    // MARK: - 대기 요청 관리
    
    /// 대기 요청 추가 (타입 정보 포함)
    func addPendingRequest<T: Decodable>(_ request: NetworkRequestConvertible, model: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        if pendingRequests.count >= maxPendingRequests {
            let removed = pendingRequests.removeFirst()
            removed.completion(.failure(CustomError.timeout))
            print("⚠️ 대기 요청 큐가 가득 참 - 오래된 요청 제거")
        }
        
        do {
            let urlRequest = try request.asURLRequest()
            let requestIdentifier = "\(urlRequest.url?.absoluteString ?? "")_\(urlRequest.httpMethod ?? "")"
            
            let isDuplicate = pendingRequests.contains { pendingRequest in
                do {
                    let pendingUrlRequest = try pendingRequest.request.asURLRequest()
                    let pendingIdentifier = "\(pendingUrlRequest.url?.absoluteString ?? "")_\(pendingUrlRequest.httpMethod ?? "")"
                    return pendingIdentifier == requestIdentifier
                } catch {
                    return false
                }
            }
            
            if isDuplicate {
                print("⚠️ 중복 요청 무시: \(requestIdentifier)")
                return
            }
            
            let pendingRequest = PendingRequest(request: request, model: model, completion: completion)
            pendingRequests.append(pendingRequest)
            print("대기 요청 추가: \(requestIdentifier) (총 \(pendingRequests.count)개)")
        } catch {
            completion(.failure(error))
            print("❌ 대기 요청 추가 실패: \(error)")
        }
    }
    
    /// 대기 요청 실행 (새 토큰으로)
    private func executePendingRequests() {
        let requests = pendingRequests
        pendingRequests.removeAll()
        
        print(" 대기 중인 \(requests.count)개 요청 실행")
        
        for pendingRequest in requests {
            Task {
                do {
                    let response = try await NetworkManager.shared.executeRequest(pendingRequest.request, model: pendingRequest.modelType)
                    pendingRequest.completion(.success(response))
                } catch {
                    pendingRequest.completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - 상태 확인
    var isCurrentlyRefreshing: Bool {
        return isRefreshingToken
    }
    
    var isCurrentlyTokenExpired: Bool {
        return isTokenExpired
    }
    
    var pendingRequestCount: Int {
        return pendingRequests.count
    }
}

final class NetworkManager {
    static let shared = NetworkManager()
    private let tokenRefreshManager = TokenRefreshManager.shared
    private init() {}

    func callRequest<T: Decodable>(target: NetworkRequestConvertible, model: T.Type) async throws -> T {
        try await NetworkMonitor.shared.checkConnection()
        
        // 토큰 만료 여부 확인 및 상태 설정
        let isExpired = await MainActor.run {
            let expired = try? checkTokenValiditySync(for: target)
            if expired == true {
                tokenRefreshManager.setTokenExpired(true)
            }
            return expired == true
        }
        
        // 토큰이 만료되었거나 갱신 중이면 대기 큐에 추가
        let shouldWait = await MainActor.run {
            tokenRefreshManager.isCurrentlyTokenExpired || tokenRefreshManager.isCurrentlyRefreshing
        }
        
        if shouldWait {
            print("토큰 갱신 대기 중 - 요청을 큐에 추가")
            
            return try await withCheckedThrowingContinuation { continuation in
                var hasResumed = false
                
                // MainActor에서 addPendingRequest 호출
                Task { @MainActor in
                    tokenRefreshManager.addPendingRequest(target, model: model) { result in
                        guard !hasResumed else { return }
                        hasResumed = true
                        
                        switch result {
                        case .success(let data):
                            continuation.resume(returning: data)
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
                
                // 첫 번째 만료 요청이고 갱신이 시작되지 않았으면 갱신 시작
                if isExpired {
                    Task {
                        let isRefreshing = await MainActor.run {
                            tokenRefreshManager.isCurrentlyRefreshing
                        }
                        
                        if !isRefreshing {
                            do {
                                try await tokenRefreshManager.startTokenRefresh()
                            } catch {
                                guard !hasResumed else { return }
                                hasResumed = true
                                continuation.resume(throwing: error)
                            }
                        } else {
                            print("토큰 갱신이 이미 진행 중 - 대기 중...")
                        }
                    }
                }
            }
        }
        
        // 토큰이 유효하면 즉시 요청 실행 및 트리거 해제
        await MainActor.run {
            tokenRefreshManager.setTokenExpired(false)
        }
        return try await executeRequest(target, model: model)
    }
    
    // MARK: - 토큰 유효성 검사 (동기적으로 호출 가능하도록 수정)
    private func checkTokenValiditySync(for target: NetworkRequestConvertible) throws -> Bool {
        guard let authorizedTarget = target as? AuthorizedTarget, authorizedTarget.requiresAuthorization else {
            return false
        }

        let now = Int(Date().timeIntervalSince1970)
        let accessExp = UserDefaultsManager.shared.getInt(forKey: .expAccess)
        
        return now >= accessExp // AccessToken 만료 여부 반환
    }
    
    // MARK: - 개별 요청 실행
    func executeRequest<T: Decodable>(_ target: NetworkRequestConvertible, model: T.Type) async throws -> T {
        let request = try target.asURLRequest()
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CustomError.unknown(code: -1, message: "유효하지 않은 응답입니다.")
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            print("❌ HTTP 에러 발생: 상태 코드: \(httpResponse.statusCode), URL: \(request.url?.absoluteString ?? "알 수 없음"), 메서드: \(request.httpMethod ?? "알 수 없음")")
            throw CustomError.from(code: httpResponse.statusCode, router: target)
        }
        
        if data.isEmpty || String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            if T.self == EmptyResponseDTO.self {
                return EmptyResponseDTO() as! T
            }
        }
        
        do {
            let decoded = try Self.makeDecoder().decode(T.self, from: data)
            return decoded
        } catch let decodingError as DecodingError {
            print(" 디코딩 실패: \(decodingError)")
            throw CustomError.unknown(code: 500, message: "디코딩 실패: \(decodingError.localizedDescription)")
        } catch {
            print(" 기타 에러: \(error)")
            throw CustomError.unknown(code: 500, message: error.localizedDescription)
        }
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
    
    // MARK: - RefreshToken 만료 처리
    func handleRefreshTokenExpiration() async {
        print(" Refresh Token 만료 - 자동 로그아웃 처리")
        
        // Refresh Token 만료 시에도 디바이스 토큰 무효화 (서버에 빈 문자열 전송)
        do {
            let emptyDeviceToken = DeviceTokenRequestDTO(deviceToken: "")
            let _: EmptyResponseDTO = try await NetworkManager.shared.callRequest(target: UserRouter.deviceTokenUpdate(emptyDeviceToken), model: EmptyResponseDTO.self)
            print(" Refresh Token 만료 시 디바이스 토큰 무효화 성공")
        } catch {
            print("❌ Refresh Token 만료 시 디바이스 토큰 무효화 실패: \(error.localizedDescription)")
        }
        
        await MainActor.run {
            // 토큰 및 프로필 데이터 제거
            UserDefaultsManager.shared.removeObject(forKey: .accessToken)
            UserDefaultsManager.shared.removeObject(forKey: .refreshToken)
            UserDefaultsManager.shared.removeObject(forKey: .profileData)
            
            // 알림 관련 데이터 초기화
            ChatNotificationCountManager.shared.clearAllCounts()
            TemporaryLastMessageManager.shared.clearAllTemporaryMessages()
            CustomNotificationManager.shared.clearAllNotifications()
            
            // 로그인 상태 변경
            UserDefaults.standard.set(false, forKey: TextResource.Global.isLoggedIn.text)
        }
    }
    
    // MARK: - File Download (이미지 캐싱과 통합)
    func downloadFile(from serverPath: String) async throws -> (localPath: String, image: UIImage?) {
        // 빈 경로 체크
        guard !serverPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("⚠️ [NetworkManager] serverPath가 빈 문자열입니다")
            throw CustomError.invalidURL
        }
        
        guard let fullURL = URL(string: BaseURL.baseV1 + serverPath) else {
            throw CustomError.invalidURL
        }
        var request = URLRequest(url: fullURL)
        
        // SeSACKey 헤더 추가 (API 키 인증)
        request.setValue(AppConfig.apiKey, forHTTPHeaderField: "SeSACKey")
        
        // Authorization 헤더 추가 (토큰 인증)
        if let accessToken = UserDefaultsManager.shared.getString(forKey: .accessToken) {
            request.setValue(accessToken, forHTTPHeaderField: "Authorization")
        }
        
        let networkRequest = SimpleNetworkRequest(urlRequest: request)
        return try await downloadFileFromRequest(networkRequest)
    }
    
    // MARK: - URLRequest로부터 파일 다운로드
    private func downloadFileFromRequest(_ target: NetworkRequestConvertible) async throws -> (localPath: String, image: UIImage?) {
        // 토큰 만료 여부 확인 및 상태 설정
        let isExpired = await MainActor.run {
            let expired = try? checkTokenValiditySync(for: target)
            if expired == true {
                tokenRefreshManager.setTokenExpired(true)
            }
            return expired == true
        }
        
        // 토큰이 만료되었거나 갱신 중이면 대기 큐에 추가
        let shouldWait = await MainActor.run {
            tokenRefreshManager.isCurrentlyTokenExpired || tokenRefreshManager.isCurrentlyRefreshing
        }
        
        if shouldWait {
            print("이미지 다운로드 대기 중 - 토큰 갱신 진행 중")
            
            return try await withCheckedThrowingContinuation { continuation in
                var hasResumed = false
                
                // MainActor에서 addPendingRequest 호출
                Task { @MainActor in
                    tokenRefreshManager.addPendingRequest(target, model: Data.self) { result in
                        guard !hasResumed else { return }
                        hasResumed = true
                        
                        switch result {
                        case .success(let data):
                            Task {
                                do {
                                    let (localPath, image) = try await self.processImageDownload(data: data as! Data, request: target)
                                    continuation.resume(returning: (localPath, image))
                                } catch {
                                    continuation.resume(throwing: error)
                                }
                            }
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
                
                // 첫 번째 만료 요청이고 갱신이 시작되지 않았으면 갱신 시작
                if isExpired {
                    Task {
                        let isRefreshing = await MainActor.run {
                            tokenRefreshManager.isCurrentlyRefreshing
                        }
                        
                        if !isRefreshing {
                            do {
                                try await tokenRefreshManager.startTokenRefresh()
                            } catch {
                                guard !hasResumed else { return }
                                hasResumed = true
                                continuation.resume(throwing: error)
                            }
                        } else {
                            print(" 토큰 갱신이 이미 진행 중 - 대기 중...")
                        }
                    }
                }
            }
        }
        
        // 토큰이 유효하면 즉시 요청 실행 및 트리거 해제
        await MainActor.run {
            tokenRefreshManager.setTokenExpired(false)
        }
        return try await processImageDownloadRequest(target)
    }
    
    // MARK: - 이미지 다운로드 처리 헬퍼 메서드
    private func processImageDownloadRequest(_ target: NetworkRequestConvertible) async throws -> (localPath: String, image: UIImage?) {
        let request = try target.asURLRequest()
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("❌ 파일 다운로드 에러: 상태 코드: \((response as? HTTPURLResponse)?.statusCode ?? -1), URL: \(request.url?.absoluteString ?? "알 수 없음")")
            throw CustomError.from(code: (response as? HTTPURLResponse)?.statusCode ?? -1, router: "FileDownload")
        }
        
        let fileName = (request.url?.lastPathComponent ?? "unknown_file")
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let localPath = documentsPath.appendingPathComponent("Downloads").appendingPathComponent(fileName)
        
        try FileManager.default.createDirectory(at: localPath.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: localPath)
        
        let fileExtension = (fileName as NSString).pathExtension.lowercased()
        let image: UIImage? = ["jpg", "jpeg", "png", "gif", "webp"].contains(fileExtension) ? UIImage(data: data) : nil
        
        return (localPath.path, image)
    }
    
    private func processImageDownload(data: Data, request: NetworkRequestConvertible) async throws -> (localPath: String, image: UIImage?) {
        let urlRequest = try request.asURLRequest()
        let fileName = (urlRequest.url?.lastPathComponent ?? "unknown_file")
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let localPath = documentsPath.appendingPathComponent("Downloads").appendingPathComponent(fileName)
        
        try FileManager.default.createDirectory(at: localPath.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: localPath)
        
        let fileExtension = (fileName as NSString).pathExtension.lowercased()
        let image: UIImage? = ["jpg", "jpeg", "png", "gif", "webp"].contains(fileExtension) ? UIImage(data: data) : nil
        
        return (localPath.path, image)
    }
    
    func downloadFiles(from serverPaths: [String]) async throws -> [String: (localPath: String, image: UIImage?)] {
        var results: [String: (localPath: String, image: UIImage?)] = [:]
        
        try await withThrowingTaskGroup(of: (String, String, UIImage?).self) { group in
            for serverPath in serverPaths {
                group.addTask {
                    let result = try await self.downloadFile(from: serverPath)
                    return (serverPath, result.localPath, result.image)
                }
            }
            
            for try await (serverPath, localPath, image) in group {
                results[serverPath] = (localPath, image)
            }
        }
        
        return results
    }
}

// MARK: - URLRequest를 NetworkRequestConvertible로 래핑하는 헬퍼 클래스
private struct SimpleNetworkRequest: NetworkRequestConvertible {
    let urlRequest: URLRequest
    
    init(urlRequest: URLRequest) {
        self.urlRequest = urlRequest
    }
    
    func asURLRequest() throws -> URLRequest {
        return urlRequest
    }
}
