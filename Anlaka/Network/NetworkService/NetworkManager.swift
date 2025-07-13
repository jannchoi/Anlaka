//
//  NetworkManager.swift
//  Anlaka
//
//  Created by 최정안 on 5/12/25.
//

import Foundation
import UIKit

final class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    func callRequest<T: Decodable>(target: NetworkRequestConvertible, model: T.Type) async throws -> T {
        try await NetworkMonitor.shared.checkConnection()
        
        try await prepareAuthorizationIfNeeded(for: target)
        
        let request = try target.asURLRequest()
        //print("🧶 Request:\n\(request)")
        let (data, response) = try await URLSession.shared.data(for: request)

        // ✅ 응답 타입 확인
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CustomError.unknown(code: -1, message: "유효하지 않은 응답입니다.")
        }

        // ✅ 상태 코드 검사
        guard 200..<300 ~= httpResponse.statusCode else {
            print("❌ HTTP 에러 발생:")
            print("   상태 코드: \(httpResponse.statusCode)")
            print("   URL: \(request.url?.absoluteString ?? "알 수 없음")")
            print("   메서드: \(request.httpMethod ?? "알 수 없음")")
            print("   헤더: \(request.allHTTPHeaderFields ?? [:])")
            if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
                print("   요청 본문: \(bodyString)")
            }
            throw CustomError.from(code: httpResponse.statusCode, router: target)
        }

        if let rawJSON = String(data: data, encoding: .utf8) {
            //print("🧤Raw Response:\n\(rawJSON)")
        } else {
            print("⚠️ Raw 데이터 UTF-8 디코딩 실패")
        }
        
        // ✅ 빈 응답 처리 (DELETE 요청의 경우)
        if data.isEmpty || String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            // 빈 응답인 경우 기본값으로 초기화된 객체 반환
            if T.self == EmptyResponseDTO.self {
                return EmptyResponseDTO() as! T
            }
        }
        
        // ✅ JSON 디코딩
        do {
            let decoded = try Self.makeDecoder().decode(T.self, from: data)
            return decoded
        } catch let decodingError as DecodingError {
            print("🔍 디코딩 실패:")
            print("   URL: \(request.url?.absoluteString ?? "알 수 없음")")
            print("   에러: \(decodingError)")
            if let rawJSON = String(data: data, encoding: .utf8) {
                print("   응답 데이터: \(rawJSON)")
            }
            throw CustomError.unknown(code: 500, message: "디코딩 실패: \(decodingError.localizedDescription)")
        } catch {
            print("🔍 기타 에러:")
            print("   URL: \(request.url?.absoluteString ?? "알 수 없음")")
            print("   에러: \(error)")
            throw CustomError.unknown(code: 500, message: error.localizedDescription)
        }
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
    
    private func prepareAuthorizationIfNeeded(for target: NetworkRequestConvertible) async throws {
        guard let authorizedTarget = target as? AuthorizedTarget, authorizedTarget.requiresAuthorization else {
            return
        }

        let now = Int(Date().timeIntervalSince1970)

        let accessExp = UserDefaultsManager.shared.getInt(forKey: .expAccess)
        if now < accessExp {
            // accessToken 유효 → 아무 작업 없음
            return
        }

        // accessToken 만료 → refreshToken 확인
        let refreshExp = UserDefaultsManager.shared.getInt(forKey: .expRefresh)
        if now >= refreshExp {
            throw CustomError.expiredRefreshToken
        }

        // ✅ refreshToken 유효하므로 accessToken 재발급 시도
//        let refreshToken = UserDefaultsManager.shared.getString(forKey: .refreshToken) ?? ""
        let refreshRequest = AuthRouter.getRefreshToken

        let response = try await callRequest(target: refreshRequest, model: RefreshTokenResponseDTO.self)
        UserDefaultsManager.shared.set(response.accessToken, forKey: .accessToken)
        UserDefaultsManager.shared.set(response.refreshToken, forKey: .refreshToken)
    }
    
    // MARK: - File Download
    func downloadFile(from serverPath: String) async throws -> (localPath: String, image: UIImage?) {
        guard let baseURL = URL(string: BaseURL.baseURL) else {
            throw CustomError.invalidURL
        }
        
        let fullURL = baseURL.appendingPathComponent(serverPath)
        
        var request = URLRequest(url: fullURL)
        
        // Authorization 헤더 추가
        if let accessToken =
            UserDefaultsManager.shared.getString(forKey: .accessToken){
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CustomError.nilResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ 파일 다운로드 에러 발생:")
            print("   상태 코드: \(httpResponse.statusCode)")
            print("   URL: \(fullURL.absoluteString)")
            print("   서버 경로: \(serverPath)")
            throw CustomError.from(code: httpResponse.statusCode, router: "FileDownload")
        }
        
        // 로컬 파일 경로 생성
        let fileName = (serverPath as NSString).lastPathComponent
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let localPath = documentsPath.appendingPathComponent("Downloads").appendingPathComponent(fileName)
        
        // Downloads 디렉토리 생성
        try FileManager.default.createDirectory(at: localPath.deletingLastPathComponent(), 
                                             withIntermediateDirectories: true)
        
        // 파일 저장
        try data.write(to: localPath)
        
        // 이미지인 경우 UIImage 생성
        let fileExtension = (fileName as NSString).pathExtension.lowercased()
        let image: UIImage?
        
        if ["jpg", "jpeg", "png", "gif", "webp"].contains(fileExtension) {
            image = UIImage(data: data)
        } else {
            image = nil
        }
        
        return (localPath.path, image)
    }
    
    func downloadFiles(from serverPaths: [String]) async throws -> [String: (localPath: String, image: UIImage?)] {
        var results: [String: (localPath: String, image: UIImage?)] = [:]
        
        // 병렬로 다운로드
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
