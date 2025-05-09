//
//  NetworkManager.swift
//  Anlaka
//
//  Created by 최정안 on 5/12/25.
//

import Foundation

final class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    func callRequest<T: Decodable>(target: NetworkRequestConvertible, model: T.Type) async throws -> T {
        try await NetworkMonitor.shared.checkConnection()
        let request = try target.asURLRequest()

        let (data, response) = try await URLSession.shared.data(for: request)

        // ✅ 응답 타입 확인
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown(code: -1, message: "유효하지 않은 응답입니다.")
        }

        // ✅ 상태 코드 검사
        guard 200..<300 ~= httpResponse.statusCode else {
            throw NetworkError.from(code: httpResponse.statusCode, router: target)
        }

        if let rawJSON = String(data: data, encoding: .utf8) {
            print("📦 Raw Response:\n\(rawJSON)")
        } else {
            print("⚠️ Raw 데이터 UTF-8 디코딩 실패")
        }
        
        // ✅ JSON 디코딩
        do {
            let decoded = try Self.makeDecoder().decode(T.self, from: data)
            return decoded
        } catch let decodingError as DecodingError {
            print("🔍 디코딩 실패: \(decodingError)")
            throw NetworkError.unknown(code: 500, message: "디코딩 실패: \(decodingError.localizedDescription)")
        } catch {
            throw NetworkError.unknown(code: 500, message: error.localizedDescription)
        }
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

}
