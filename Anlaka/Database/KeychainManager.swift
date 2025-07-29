//
//  KeychainManager.swift
//  Anlaka
//
//  Created by 최정안 on 5/13/25.
//

import Foundation
import Security

enum KeychainKey: String {
    case accessToken
    case refreshToken
    case appleIdToken
    case kakaoToken
    
    /// 이 키로 저장되는 값이 JWT 토큰인지 여부
    var requiresJWTDecoding: Bool {
        switch self {
        case .accessToken, .refreshToken:
            return true
        default:
            return false
        }
    }
    
    /// JWT 디코딩 시 저장할 만료 시간 키 (UserDefaults에 저장)
    var correspondingExpKey: String? {
        switch self {
        case .accessToken: return "expAccess"
        case .refreshToken: return "expRefresh"
        default: return nil
        }
    }
}

final class KeychainManager {
    static let shared = KeychainManager()
    
    private let service = "com.jann.Anlaka"
    private let accessGroup: String? = nil // App Groups 사용 시 설정
    
    private init() {}
    
    // MARK: - Save
    
    func set(_ value: String, forKey key: KeychainKey) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: value.data(using: .utf8)!
        ]
        
        // 기존 데이터 삭제
        SecItemDelete(query as CFDictionary)
        
        // 새 데이터 저장
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            // JWT 토큰이라면 만료 시간도 UserDefaults에 저장
            if key.requiresJWTDecoding,
               let exp = JWTDecoder.decodeExpiration(from: value),
               let expKey = key.correspondingExpKey {
                UserDefaults.standard.set(exp, forKey: expKey)
                print("✅ Keychain 저장 성공: \(key.rawValue), 만료시간: \(exp)")
            } else {
                print("✅ Keychain 저장 성공: \(key.rawValue)")
            }
        } else {
            print("❌ Keychain 저장 실패: \(key.rawValue), 상태: \(status)")
        }
    }
    
    // MARK: - Get
    
    func getString(forKey key: KeychainKey) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    // MARK: - Remove
    
    func remove(forKey key: KeychainKey) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess || status == errSecItemNotFound {
            // JWT 토큰이라면 만료 시간도 UserDefaults에서 삭제
            if key.requiresJWTDecoding,
               let expKey = key.correspondingExpKey {
                UserDefaults.standard.removeObject(forKey: expKey)
            }
            print("✅ Keychain 삭제 성공: \(key.rawValue)")
        } else {
            print("❌ Keychain 삭제 실패: \(key.rawValue), 상태: \(status)")
        }
    }
    
    // MARK: - Check Existence
    
    func contains(_ key: KeychainKey) -> Bool {
        return getString(forKey: key) != nil
    }
    
    // MARK: - Migration
    
    /// UserDefaults에서 Keychain으로 토큰 마이그레이션
    func migrateFromUserDefaults() {
        print("🔄 Keychain 마이그레이션 시작")
        
        let userDefaults = UserDefaults.standard
        var migratedCount = 0
        
        // 액세스 토큰 마이그레이션
        if let accessToken = userDefaults.string(forKey: "accessToken") {
            set(accessToken, forKey: .accessToken)
            userDefaults.removeObject(forKey: "accessToken")
            migratedCount += 1
            print("✅ accessToken 마이그레이션 완료")
        }
        
        // 리프레시 토큰 마이그레이션
        if let refreshToken = userDefaults.string(forKey: "refreshToken") {
            set(refreshToken, forKey: .refreshToken)
            userDefaults.removeObject(forKey: "refreshToken")
            migratedCount += 1
            print("✅ refreshToken 마이그레이션 완료")
        }
        
        // Apple ID 토큰 마이그레이션
        if let appleIdToken = userDefaults.string(forKey: "appleIdToken") {
            set(appleIdToken, forKey: .appleIdToken)
            userDefaults.removeObject(forKey: "appleIdToken")
            migratedCount += 1
            print("✅ appleIdToken 마이그레이션 완료")
        }
        
        // 카카오 토큰 마이그레이션
        if let kakaoToken = userDefaults.string(forKey: "kakaoToken") {
            set(kakaoToken, forKey: .kakaoToken)
            userDefaults.removeObject(forKey: "kakaoToken")
            migratedCount += 1
            print("✅ kakaoToken 마이그레이션 완료")
        }
        
        if migratedCount > 0 {
            print("✅ Keychain 마이그레이션 완료: \(migratedCount)개 토큰")
        } else {
            print("ℹ️ 마이그레이션할 토큰이 없습니다")
        }
    }
    
    // MARK: - Clear All
    
    /// 모든 Keychain 데이터 삭제 (로그아웃 시 사용)
    func clearAll() {
        print("🗑️ Keychain 전체 삭제 시작")
        
        let keys: [KeychainKey] = [.accessToken, .refreshToken, .appleIdToken, .kakaoToken]
        
        for key in keys {
            remove(forKey: key)
        }
        
        print("✅ Keychain 전체 삭제 완료")
    }
} 